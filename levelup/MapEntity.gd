extends Node2D
class_name MapEntity

var tilemap_mgr
var map_position:Vector2
var map_layer:String
var map_config = {}

func on_map_place(_tilemap_mgr, layer_name:String, cell:Vector2):
	self.tilemap_mgr = _tilemap_mgr
	self.map_position = cell
	self.map_layer = layer_name
	self.map_config = tilemap_mgr.get_tile_config(cell.x, cell.y)
	if !EventBus.is_connected("pre_save_game", self, "pre_save_game"):
		EventBus.connect("pre_save_game", self, "pre_save_game")
		EventBus.connect("post_load_game", self, "post_load_game")
	if map_config == null:
		map_config = {}
	if typeof(map_config) == TYPE_DICTIONARY:
		var save_data = GameData.get_map_data(map_layer, map_position)
		if typeof(save_data) == TYPE_DICTIONARY:
			for k in save_data.keys():
				map_config[k] = save_data[k]
		Util.config(self, map_config)

func update_config(c:Dictionary):
	GameData.set_map_data(map_layer, map_position, c)

func change_tile(val):
	if val is String:
		val = tilemap_mgr.get_tileset(map_layer).find_tile_by_name(val)
	if tilemap_mgr:
		tilemap_mgr.set_tile(map_layer, map_position.x, map_position.y, val)

func pre_save_game():
	pass

func post_load_game():
	pass
