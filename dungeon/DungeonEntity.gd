extends Spatial
class_name DungeonEntity

var dungeon
var map_position:Vector2
var map_layer:String
var map_config = {}

func on_map_place(_dungeon, layer_name:String, cell:Vector2):
	self.dungeon = _dungeon
	self.map_position = cell
	self.map_layer = layer_name
	self.map_config = dungeon.get_tile_config(cell.x, cell.y)
	if map_config == null:
		map_config = {}
	if typeof(map_config) == TYPE_DICTIONARY:
		var save_data = GameData.get_map_data(map_layer, map_position)
		if typeof(save_data) == TYPE_DICTIONARY:
			for k in save_data.keys():
				map_config[k] = save_data[k]
		Util.config(self, map_config)

func change_tile(val):
	if val is String:
		val = dungeon.get_tileset(map_layer).find_tile_by_name(val)
	if dungeon:
		dungeon.set_tile(map_layer, map_position.x, map_position.y, val)
