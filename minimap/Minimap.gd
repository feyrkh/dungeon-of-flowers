extends Node2D

const MINIMAP_OFFSET:Vector2 = Vector2(-32*2, -32*2)

onready var PlayerIcon:Sprite = find_node("PlayerIcon")
onready var Map:TileMap = find_node("TileMap")
onready var View:Viewport = find_node("Viewport")
onready var MinimapHandle:Node2D = find_node("MinimapHandle")

func _ready():
	EventBus.connect("uncovered_map_tile", self, "_on_uncovered_map_tile")
	EventBus.connect("update_minimap", self, "_on_update_minimap")
	EventBus.connect("new_player_location", self, "_on_new_player_location")

func _on_uncovered_map_tile(x, y, tile_type):
	var tile_id = Map.tile_set.find_tile_by_name(tile_type)
	Map.set_cell(x, y, tile_id, false, false, false)

func _on_new_player_location(map_x, map_y, rot_deg):
	var new_player_pos = Vector2(-map_x*32, -map_y*32)
	PlayerIcon.rotation_degrees = -rot_deg
	Map.position = new_player_pos - MINIMAP_OFFSET

func _on_update_minimap():
	Map.update_dirty_quadrants()
