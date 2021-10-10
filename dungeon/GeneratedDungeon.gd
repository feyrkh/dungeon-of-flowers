extends Spatial

const Player = preload("res://dungeon/Player.tscn")

const tile_wall = preload("res://dungeon/wall.tscn")
const tile_corridor = preload("res://dungeon/Corridor.tscn")
const tile_torch = preload("res://dungeon/torchwall.tscn")

const start_combat_sfx = preload("res://sound/mixkit-medieval-show-fanfare-announcement-226.wav")

const tiles = {
	"#": [tile_torch, tile_wall],
	" ": tile_corridor,
	"@": tile_corridor,
}

var player
var map_name:String = "an unknown place"
var combat_grace_period:int = 4
var combat_grace_period_counter:int
var combat_chance_per_tile:float = 0.1
var property_types:Dictionary = {}
var randseed:int
var combatMusic:String
var exploreMusic:String

onready var Map:Spatial = find_node("Map")
onready var Combat:Control = find_node("Combat")
onready var Fader:Control = find_node("Fader")
onready var BackgroundBlur:Control = find_node("BackgroundBlur")
onready var MapName:Label = find_node("MapName")
onready var IdleHud:Control = find_node("IdleHud")

func _ready():
	EventBus.connect("post_new_game", self, "on_post_new_game")
	EventBus.connect("finalize_new_game", self, "on_finalize_new_game")
	EventBus.connect("post_load_game", self, "on_post_load_game")
	EventBus.connect("finalize_load_game", self, "on_finalize_load_game")
	CombatMgr.connect("combat_start", self, "_on_combat_start")
	CombatMgr.connect("combat_end", self, "_on_combat_end")

func on_post_load_game():
	load_from_file()
	player.global_transform.origin = Vector3(GameData.world_tile_position.x*3, 0, GameData.world_tile_position.y*3)
	player.rotation_degrees.y = GameData.player_rotation

func on_finalize_load_game():
	pass
	
func on_post_new_game():
	load_from_file()
	
func on_finalize_new_game():
	QuestMgr.check_quest_progress()
	
func load_from_file():
	GameData.set_rand_seed()
	for prop in get_property_list():
		property_types[prop.name] = prop.type
	var file = File.new()
	var err = file.open(GameData.cur_dungeon, File.READ)
	if err != 0:
		printerr(GameData.cur_dungeon, " : Failed to open dungeon file while loading, got error: ", err)
		return
	var content = file.get_line()
	while content != "map:":
		process_config_line(content)
		content = file.get_line()
	process_map(file)
	file.close()
	combat_grace_period_counter = combat_grace_period
	CombatMgr.register(player, self)
	MapName.text = map_name
	IdleHud.modulate.a = 0
	MusicCrossFade.cross_fade("res://music/explore1.mp3", 3, true)


	
func _on_combat_start():
	MusicCrossFade.cross_fade("res://music/battle1.ogg", 3, false)
	AudioPlayerPool.play(start_combat_sfx)

func _on_combat_end():
	MusicCrossFade.cross_fade("res://music/explore1.mp3", 3, true)

func _on_player_tile_move_complete():
	if !QuestMgr.can_enter_combat():
		return
	if combat_grace_period_counter > 0:
		combat_grace_period_counter -= 1
	else:
		if combat_chance_per_tile >= randf():
			CombatMgr.trigger_combat(null)
			combat_grace_period_counter = combat_grace_period

func process_config_line(line:String):
	var chunks = line.split(":", false, 1)
	if chunks.size() == 2:
		match property_types.get(chunks[0]):
			TYPE_INT:
				set(chunks[0], int(chunks[1]))
			TYPE_REAL:
				set(chunks[0], float(chunks[1]))
			TYPE_STRING:
				set(chunks[0], chunks[1])
			_: printerr("Unexpected property type: ", property_types.get(chunks[0]))
	
func process_map(file):
	var z = 0
	var content = file.get_line()
	while content != "":
		var x = 0
		for c in content:
			if c == "@":
				player = Player.instance()
				player.transform.origin = Vector3(3*x, 0, 3*z)
				#player.transform = player.transform.rotated(Vector3.UP, deg2rad(90))
				add_child(player)
			var tileScene = tiles.get(c)
			if tileScene is Array:
				tileScene = tileScene[randi()%tileScene.size()]
			if tileScene == null:
				printerr("Undefined tile character in "+GameData.cur_dungeon+" at ("+x+","+z+") '"+c+"'")
				x += 1
				continue
			var tile:Spatial = tileScene.instance()
			add_child(tile)
			tile.transform.origin = Vector3(3*x, 0, 3*z) 
			if tile.is_in_group("rotated"):
				var rotate_amt = deg2rad(randi()%4 * 90)
				tile.transform.basis = tile.transform.basis.rotated(Vector3.UP, rotate_amt)
			x += 1
		content = file.get_line()
		z += 1
	file.close()
