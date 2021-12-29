extends Node
class_name TilemapMgr

export var tile_name_prefix = "~"
export var tile_size = 3 # how many units (or pixels) each tile takes up in width/height
export var add_under_tilemap = false # if true, new scenes are attached to to the tilemap layer, otherwise to this object

var map_scene:Node # The loaded scene which contains each of the TileMap layers which are used to render the 3d map
var map_index:Dictionary = {} # The loaded scenes which were created by reading the map_scene TileMap layers; map_index["ground"][Vector2(0,0)] is the top-left corner of the ground layer
var tilemaps:Dictionary = {} # The TileMap nodes for each layer; tilemaps["ground"].get_cell(0, 0) is the tile ID of the top left tile
var tilesets:Dictionary = {} # The TileSet nodes for each layer; tilesets["ground"].find_tile_by_name("~wall") is the ID of the ~wall tile
var property_types:Dictionary = {}
var tile_config = {}
var tiles

func load_from_file(map_config_file, map_scene_file_or_node, _tiles):
	GameData.set_rand_seed()
	self.tiles = _tiles
	map_index = {}
	tilemaps = {}
	tilesets = {}
	for prop in owner.get_property_list():
		property_types[prop.name] = prop.type
	var json = Util.read_json(map_config_file)
	for k in json.keys():
		process_config_line(k, json[k])
	process_map(map_scene_file_or_node)


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
	EventBus.emit_signal("map_tile_changed", layer, x, y, tile)

func get_tile_config(x:int, y:int):
	var tile_name = get_tile_name("config", x, y)
	return tile_config.get(tile_name, {})

func get_tile_name(layer, x:int, y:int):
	var tile_id = get_tile(layer, x, y)
	if tile_id == -1:
		return null
	return tilesets[layer].tile_get_name(tile_id)
func get_tileset(layer):
	return tilesets.get(layer, null)

func get_all_tile_scenes(coords:Vector2):
	var result = []
	for child in tilemaps.values():
		var tilemap:TileMap = child as TileMap
		if tilemap == null:
			continue
		var scene = get_tile_scene(tilemap.name, coords)
		if scene != null:
			result.append(scene)
	return result

func get_tile_scene(layer:String, coords:Vector2):
	if !map_index.has(layer):
		return null
	var scene = map_index[layer].get(coords, null)
	if !is_instance_valid(scene):
		return null
	return scene

func set_tile_scene(layer:String, coords:Vector2, scene:Node):
	if !map_index.has(layer):
		map_index[layer] = {}
	map_index[layer][coords] = scene
	if scene != null and scene.get_parent() == null:
		var tile_scene_parent = get_parent().find_node(layer+"_children", true, false)
		tile_scene_parent.add_child(scene)

func load_tile(tile_name, tile_val):
	print("Tile '%s'=%s"%[tile_name, tile_val])
	if tile_val is String:
		tiles[tile_name_prefix+tile_name] = load("res://"+tile_val)
	elif tile_val is Dictionary:
		tiles[tile_name_prefix+tile_name] = tile_val
		if tile_val["scene"] is String:
			tile_val["scene"] = load("res://"+tile_val["scene"])

func process_config_line(key, val):
	if key == "tiles":
		for tile_name in val.keys():
			load_tile(tile_name, val[tile_name])
	elif key == "config":
		tile_config = val
	else:
		match property_types.get(key):
			TYPE_INT:
				owner.set(key, int(val))
			TYPE_REAL:
				owner.set(key, float(val))
			TYPE_STRING:
				owner.set(key, val)
			_: printerr("Unexpected property type: ", property_types.get(key))

func process_map(map_scene_file_or_node):
	if map_scene_file_or_node is String:
		if is_instance_valid(map_scene):
			map_scene.queue_free()
		map_scene = load(map_scene_file_or_node).instance()
	else:
		map_scene = map_scene_file_or_node
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
	if owner.has_method("process_tileset"):
		owner.process_tileset(layer)

func process_tilemap_layer(layer:TileMap, layer_name:String):
	var tileset:TileSet = layer.tile_set
	var tile_scene_parent:Node
	if add_under_tilemap:
		tile_scene_parent = Node2D.new()
		tile_scene_parent.name = layer_name+"_children"
		layer.get_parent().add_child_below_node(layer, tile_scene_parent, true)
	else:
		tile_scene_parent = self
	var override_data = GameData.get_map_layer_data(layer_name).get("_tiles", {})
	for override_cell in override_data.keys():
		layer.set_cell(override_cell.x, override_cell.y, override_data.get(override_cell, -1))
	var cells = layer.get_used_cells()
	var has_custom_handler = owner.has_method("custom_tile_handler")
	var has_tile_instance_handler = owner.has_method("custom_tile_instance_handler")
	for cell in cells:
		var tile_id = layer.get_cell(cell.x, cell.y)
		var tile_name = tileset.tile_get_name(tile_id)
		if tile_name == "" or tile_name == null:
			continue
		if has_custom_handler:
			if owner.custom_tile_handler(layer, layer_name, tileset, cell, tile_name, tile_id):
				continue
		var tile_packed_scene = tiles.get(tile_name)
		var t_config = null
		if tile_packed_scene is Dictionary:
			t_config = tile_packed_scene["props"]
			tile_packed_scene = tile_packed_scene["scene"]
		if tile_packed_scene:
			var tile_scene = tile_packed_scene.instance()
			tile_scene_parent.add_child(tile_scene)
			if t_config:
				Util.config(tile_scene, t_config)
			set_tile_scene(layer_name, cell, tile_scene)
			if tile_scene is Spatial:
				tile_scene.transform.origin = Vector3(tile_size*cell.x, 0, tile_size*cell.y)
			else:
				tile_scene.position = Vector2(tile_size*cell.x, tile_size*cell.y)
			if tile_scene.has_method("on_map_place"):
				tile_scene.on_map_place(self, layer_name, cell)
			if has_tile_instance_handler:
				owner.custom_tile_instance_handler(layer, layer_name, tileset, cell, tile_name, tile_id, tile_scene)
