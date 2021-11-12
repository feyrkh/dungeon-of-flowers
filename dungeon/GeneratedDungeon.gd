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

const IN_FOG_MIN = 1.5
const IN_FOG_MAX = -10
const OUT_FOG_MIN = -0.1
const OUT_FOG_MAX = -10

var player
var map_name:String = "an unknown place"
var combat_grace_period:int = 4
var combat_grace_period_counter:int
var combat_chance_per_tile:float = 0.1
var property_types:Dictionary = {}
var randseed:int
var combatMusic:String
var exploreMusic:String
var map_scene:Node # The loaded scene which contains each of the TileMap layers which are used to render the 3d map
var map_index:Dictionary = {} # The loaded scenes which were created by reading the map_scene TileMap layers; map_index["ground"][Vector2(0,0)] is the top-left corner of the ground layer
var tilemaps:Dictionary = {} # The TileMap nodes for each layer; tilemaps["ground"].get_cell(0, 0) is the tile ID of the top left tile
var tilesets:Dictionary = {} # The TileSet nodes for each layer; tilesets["ground"].find_tile_by_name("~wall") is the ID of the ~wall tile
var wall_tile_id
var corridor_tile_id
var pollen_tile_id 
var block_pollen_tile_id
var orientation_tiles = {}
var in_pollen = false

onready var Map:Spatial = find_node("Map")
onready var Combat:Control = find_node("Combat")
onready var Fader:Control = find_node("Fader")
onready var MapName:Label = find_node("MapName")
onready var IdleHud:Control = find_node("IdleHud")

func _ready():
	EventBus.connect("post_new_game", self, "on_post_new_game")
	EventBus.connect("finalize_new_game", self, "on_finalize_new_game")
	EventBus.connect("post_load_game", self, "on_post_load_game")
	EventBus.connect("finalize_load_game", self, "on_finalize_load_game")
	EventBus.connect("new_player_location", self, "on_new_player_location")
	CombatMgr.connect("combat_start", self, "_on_combat_start")
	CombatMgr.connect("combat_end", self, "_on_combat_end")

func on_new_player_location(map_x, map_y, rot_deg):
	var new_in_pollen = get_tile("pollen", map_x, map_y) == pollen_tile_id
	if in_pollen == new_in_pollen:
		return
	in_pollen = new_in_pollen
	if $FogTween.is_active():
		$FogTween.remove_all()
	if in_pollen:
		$FogTween.interpolate_property($WorldEnvironment.environment, "fog_height_min", $WorldEnvironment.environment.fog_height_min, IN_FOG_MIN, 1.0)
		$FogTween.interpolate_property($WorldEnvironment.environment, "fog_height_max", $WorldEnvironment.environment.fog_height_max, IN_FOG_MAX, 1.0)
	else:
		$FogTween.interpolate_property($WorldEnvironment.environment, "fog_height_min", $WorldEnvironment.environment.fog_height_min, OUT_FOG_MIN, 1.0)
		$FogTween.interpolate_property($WorldEnvironment.environment, "fog_height_max", $WorldEnvironment.environment.fog_height_max, OUT_FOG_MAX, 1.0)
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
	GameData.set_rand_seed()
	map_index = {}
	tilemaps = {}
	tilesets = {}
	for prop in get_property_list():
		property_types[prop.name] = prop.type
	var file = File.new()
	var err = file.open("res://data/map/"+GameData.cur_dungeon+".txt", File.READ)
	if err != 0:
		printerr(GameData.cur_dungeon, " : Failed to open dungeon file while loading, got error: ", err)
		return
	var content = file.get_line()
	while content != "map:" and !file.eof_reached():
		process_config_line(content)
		content = file.get_line()
	file.close()
	process_map(GameData.cur_dungeon)
	combat_grace_period_counter = combat_grace_period
	CombatMgr.register(player, self)
	MapName.text = map_name
	IdleHud.modulate.a = 0
	MusicCrossFade.cross_fade("res://music/explore1.mp3", 3, true)
	
func get_tile(layer:String, x:int, y:int) -> int:
	var tilemap:TileMap = tilemaps.get(layer, null)
	if tilemap == null:
		return -1
	var cell = tilemap.get_cell(x, y)
	return cell

func set_tile(layer:String, x:int, y:int, tile:int):
	var tilemap:TileMap = tilemaps.get(layer, null)
	if tilemap == null:
		return
	tilemap.set_cell(x, y, tile)
	EventBus.emit_signal("map_tile_changed", x, y, tile)

func get_tile_scene(layer:String, coords:Vector2):
	if !map_index.has(layer):
		return null
	var scene = map_index[layer].get(coords, null)
	if !is_instance_valid(scene):
		return null
	return scene	

func set_tile_scene(layer:String, coords:Vector2, scene:Spatial):
	if !map_index.has(layer):
		map_index[layer] = {}
	map_index[layer][coords] = scene

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
		if chunks[0] == "tile":
			load_tile(chunks[1])
		else:
			match property_types.get(chunks[0]):
				TYPE_INT:
					set(chunks[0], int(chunks[1]))
				TYPE_REAL:
					set(chunks[0], float(chunks[1]))
				TYPE_STRING:
					set(chunks[0], chunks[1])
				_: printerr("Unexpected property type: ", property_types.get(chunks[0]))

func load_tile(tile_data):
	var chunks = tile_data.split(":", false, 1)
	if chunks.size() == 2:
		print("Tile '%s'=%s"%[chunks[0], chunks[1]])
		tiles["~"+chunks[0]] = load("res://"+chunks[1])
	
func process_map(map_filename):
	if is_instance_valid(map_scene):
		map_scene.queue_free()
	map_scene = load("res://data/map/"+map_filename+".tscn").instance()
	# preprocess/index the layers
	for layer in map_scene.get_children():
		if layer is TileMap:
			tilemaps[layer.name] = layer
			tilesets[layer.name] = layer.tile_set
			process_tileset(layer)
	# render the layers
	for layer in map_scene.get_children():
		if layer is TileMap:
			process_tilemap_layer(layer, layer.name)

func process_tileset(layer):
	var tileset:TileSet = layer.tile_set
	for tile_id in tileset.get_tiles_ids():
		var tile_name = tileset.tile_get_name(tile_id)
		match tile_name:
			"~wall": wall_tile_id = tile_id
			"~floor": corridor_tile_id = tile_id
			"~pollen": pollen_tile_id = tile_id
			"~block_pollen": block_pollen_tile_id = tile_id
			"~up": orientation_tiles[tile_id] = Vector3(0, 0, 0)
			"~down": orientation_tiles[tile_id] = Vector3(0, 180, 0)
			"~left": orientation_tiles[tile_id] = Vector3(0, 90, 0)
			"~right": orientation_tiles[tile_id] = Vector3(0, -90, 0)
	

func process_tilemap_layer(layer:TileMap, layer_name:String):
	var tileset:TileSet = layer.tile_set
	var cells = layer.get_used_cells()
	for cell in cells:
		var tile_id = layer.get_cell(cell.x, cell.y)
		var tile_name = tileset.tile_get_name(tile_id)
		if tile_name == "" or tile_name == null:
			continue
		if tile_name == "~player_spawn":
			player = Player.instance()
			player.transform.origin = Vector3(3*cell.x, 0, 3*cell.y)
			#player.transform = player.transform.rotated(Vector3.UP, deg2rad(90))
			add_child(player)
			continue
		var tile_packed_scene = tiles.get(tile_name)
		if tile_packed_scene:
			var tile_scene = tile_packed_scene.instance()
			add_child(tile_scene)
			set_tile_scene(layer_name, cell, tile_scene)
			if tile_scene.has_method("on_map_place"):
				tile_scene.on_map_place(self, layer_name, cell)
			tile_scene.transform.origin = Vector3(3*cell.x, 0, 3*cell.y)
			if layer_name != "ground":
				var orientation_tile = get_tile("orientation", cell.x, cell.y)
				var orientation_vector = orientation_tiles.get(orientation_tile, null)
				if orientation_vector:
					tile_scene.rotation_degrees = orientation_vector
			if tile_scene.is_in_group("rotated"):
				var rotate_amt = deg2rad(randi()%4 * 90)
				tile_scene.transform.basis = tile_scene.transform.basis.rotated(Vector3.UP, rotate_amt)
