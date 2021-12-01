extends Spatial

const Player = preload("res://dungeon/Player.tscn")

const tile_wall = preload("res://dungeon/Wall.tscn")
const tile_corridor = preload("res://dungeon/Corridor.tscn")
const tile_torch = preload("res://dungeon/torchwall.tscn")

const start_combat_sfx = preload("res://sound/mixkit-medieval-show-fanfare-announcement-226.wav")

const tiles = {
	"#": [tile_torch, tile_wall],
	" ": tile_corridor,
	"@": tile_corridor,
}

const IN_FOG_LIGHT = [0.05, 0.03, 0.02, 0.01, 0]
const IN_FOG_MIN = [-0.1, 1, 1.75, 2.75, 4]
const IN_FOG_COLOR = [Color("9f32ae"), Color("9f32ae"), Color("862793"), Color("7a1a84"), Color("7a1a84"), ]
const IN_FOG_DEPTH = [200, 100, 70, 60, 50]
const IN_FOG_DEPTH_START = [100, 40, 35, 30, 25]
const FOG_MAX = -5

var player
var map_name:String = "an unknown place"
var combat_grace_period:int = 4
var combat_grace_period_counter:int
var combat_chance_per_tile:float = 0.1
var randseed:int
var combatMusic:String
var exploreMusic:String
var wall_tile_id
var corridor_tile_id
var pollen_1_tile_id 
var pollen_2_tile_id 
var pollen_3_tile_id 
var pollen_4_tile_id 
var block_pollen_tile_id
var orientation_tiles = {}
var in_pollen = 0

onready var Map:Spatial = find_node("Map")
onready var Combat:Control = find_node("Combat")
onready var Fader:Control = find_node("Fader")
onready var MapName:Label = find_node("MapName")
onready var IdleHud:Control = find_node("IdleHud")
onready var TilemapMgr:Node = find_node("TilemapMgr")

func _ready():
	EventBus.connect("post_new_game", self, "on_post_new_game")
	EventBus.connect("finalize_new_game", self, "on_finalize_new_game")
	EventBus.connect("post_load_game", self, "on_post_load_game")
	EventBus.connect("finalize_load_game", self, "on_finalize_load_game")
	EventBus.connect("new_player_location", self, "on_new_player_location")
	CombatMgr.connect("combat_start", self, "_on_combat_start")
	CombatMgr.connect("combat_end", self, "_on_combat_end")

func on_new_player_location(map_x, map_y, rot_deg):
	var new_in_pollen = get_pollen_level(Vector2(map_x, map_y))
	#if in_pollen == new_in_pollen:
	#	return
	$WorldEnvironment.environment.fog_height_max = FOG_MAX
	in_pollen = new_in_pollen
	if $FogTween.is_active():
		$FogTween.remove_all()
	$FogTween.interpolate_property($WorldEnvironment.environment, "fog_height_min", $WorldEnvironment.environment.fog_height_min, IN_FOG_MIN[in_pollen], 1.0)
	$FogTween.interpolate_property($WorldEnvironment.environment, "fog_color", $WorldEnvironment.environment.fog_color, IN_FOG_COLOR[in_pollen], 1.0)
	$FogTween.interpolate_property($WorldEnvironment.environment, "fog_depth_end", $WorldEnvironment.environment.fog_depth_end, IN_FOG_DEPTH[in_pollen], 1.0)
	$FogTween.interpolate_property($WorldEnvironment.environment, "fog_depth_begin", $WorldEnvironment.environment.fog_depth_begin, IN_FOG_DEPTH_START[in_pollen], 1.0)
	$FogTween.interpolate_property($WorldEnvironment.environment, "ambient_light_energy", $WorldEnvironment.environment.ambient_light_energy, IN_FOG_LIGHT[in_pollen], 1.0)
	$FogTween.start()

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
	TilemapMgr.load_from_file("res://data/map/"+GameData.cur_dungeon+".json", "res://data/map/"+GameData.cur_dungeon+".tscn", tiles)
	combat_grace_period_counter = combat_grace_period
	CombatMgr.register(player, self)
	MapName.text = map_name
	IdleHud.modulate.a = 0
	MusicCrossFade.cross_fade("res://music/explore1.mp3", 3, true)

func get_tile(layer:String, x:int, y:int) -> int:
	return TilemapMgr.get_tile(layer, x, y)

func set_tile(layer:String, x:int, y:int, tile:int):
	return TilemapMgr.set_tile(layer, x, y, tile)

func get_tile_config(x:int, y:int):
	return TilemapMgr.get_tile_config(x, y)

func get_tile_name(layer, x:int, y:int):
	return TilemapMgr.get_tile_name(layer, x, y)
	
func get_tileset(layer):
	return TilemapMgr.get_tileset(layer)

func get_all_tile_scenes(coords:Vector2):
	return TilemapMgr.get_all_tile_scenes(coords)

func get_tile_scene(layer:String, coords:Vector2):
	return TilemapMgr.get_tile_scene(layer, coords)

func set_tile_scene(layer:String, coords:Vector2, scene:Spatial):
	return TilemapMgr.set_tile_scene(layer, coords, scene)

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
		if in_pollen > 0 and in_pollen*combat_chance_per_tile >= randf():
			CombatMgr.trigger_combat(null)
			combat_grace_period_counter = combat_grace_period
	
func get_pollen_level(coords):
	match get_tile("pollen", coords.x, coords.y):
		pollen_1_tile_id: 
			return 1
		pollen_2_tile_id: 
			return 2
		pollen_3_tile_id: 
			return 3
		pollen_4_tile_id: 
			return 4
	return 0

func can_pollen_spread(coords):
	match get_tile("ground", coords.x, coords.y):
		wall_tile_id:
			return false
		-1:
			return false
	match get_tile("pollen", coords.x, coords.y):
		block_pollen_tile_id:
			return false
	return true
	
func pollen_infest(coords, pollen_level):
	if pollen_level >= 4:
		pollen_level = 4
		print("enemy levelup at ", coords)
		EventBus.emit_signal("enemy_levelup")
	else:
		print("pollen intensity up from ", pollen_level, " at ", coords)
		var new_tile
		match pollen_level:
			0: new_tile = pollen_1_tile_id
			1: new_tile = pollen_2_tile_id
			2: new_tile = pollen_3_tile_id
			3: new_tile = pollen_4_tile_id
		set_tile("pollen", coords.x, coords.y, new_tile)


func _on_ExploreGameoverChecker_timeout():
	EventBus.emit_signal("check_explore_gameover")

func process_tileset(layer):
	var tileset:TileSet = layer.tile_set
	for tile_id in tileset.get_tiles_ids():
		var tile_name = tileset.tile_get_name(tile_id)
		match tile_name:
			"~wall": wall_tile_id = tile_id
			"~floor": corridor_tile_id = tile_id
			"~pollen": pollen_1_tile_id = tile_id
			"~pollen2": pollen_2_tile_id = tile_id
			"~pollen3": pollen_3_tile_id = tile_id
			"~pollen4": pollen_4_tile_id = tile_id
			"~block_pollen": block_pollen_tile_id = tile_id
			"~up": orientation_tiles[tile_id] = Vector3(0, 0, 0)
			"~down": orientation_tiles[tile_id] = Vector3(0, 180, 0)
			"~left": orientation_tiles[tile_id] = Vector3(0, 90, 0)
			"~right": orientation_tiles[tile_id] = Vector3(0, -90, 0)

# Called when deciding what to do with a tile - return false to say you don't want to do anything special,
# and instead instantiate whatever object might be configured for this tile
func custom_tile_handler(layer, layer_name, tileset, cell, tile_name, tile_id):
	if tile_name == "~player_spawn":
		player = Player.instance()
		player.transform.origin = Vector3(3*cell.x, 0, 3*cell.y)
		#player.transform = player.transform.rotated(Vector3.UP, deg2rad(90))
		add_child(player)
		return true
	return false

# Called after instantiating and placing a scene from a tile
func custom_tile_instance_handler(layer, layer_name, tileset, cell, tile_name, tile_id, tile_scene):
	if layer_name != "ground":
		var orientation_tile = get_tile("orientation", cell.x, cell.y)
		var orientation_vector = orientation_tiles.get(orientation_tile, null)
		if orientation_vector:
			tile_scene.rotation_degrees = orientation_vector
	if tile_scene.is_in_group("rotated"):
		var rotate_amt = deg2rad(randi()%4 * 90)
		tile_scene.transform.basis = tile_scene.transform.basis.rotated(Vector3.UP, rotate_amt)
