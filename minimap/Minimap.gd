extends Node2D

const MINIMAP_OFFSET:Vector2 = Vector2(-32*3, -32*3)

onready var PlayerIcon:Sprite = find_node("PlayerIcon")
onready var Map:TileMap = find_node("TileMap")
onready var View:Viewport = find_node("Viewport")
onready var MinimapHandle:Node2D = find_node("MinimapHandle")

var min_x = 999
var min_y = 0
var max_x = 999
var max_y = 0

func _ready():
	visible = false
	EventBus.connect("uncovered_map_tile", self, "_on_uncovered_map_tile")
	EventBus.connect("update_minimap", self, "_on_update_minimap")
	EventBus.connect("hide_minimap", self, "_on_hide_minimap")
	EventBus.connect("show_minimap", self, "_on_show_minimap")
	EventBus.connect("new_player_location", self, "_on_new_player_location")
	EventBus.connect("pre_save_game", self, "_on_pre_save")
	EventBus.connect("post_load_game", self, "_on_post_load")
	EventBus.connect("finalize_load_game", self, "_on_finalize_load")
	CombatMgr.connect("combat_start", self, "_on_combat_start")
	CombatMgr.connect("combat_end", self, "_on_combat_end")

func _on_combat_start():
	visible = false

func _on_combat_end():
	visible = true

func _on_hide_minimap():
	visible = false

func _on_show_minimap():
	visible = true

func _on_uncovered_map_tile(x, y, tile_type):
	var tile_id = Map.tile_set.find_tile_by_name(tile_type)
	Map.set_cell(x, y, tile_id, false, false, false)
	if x < min_x: min_x = x
	if x > max_x: max_x = x
	if y < min_y: min_y = y
	if y > max_y: max_y = y

func _on_new_player_location(map_x, map_y, rot_deg):
	var new_player_pos = Vector2(-map_x*32, -map_y*32)
	PlayerIcon.rotation_degrees = -rot_deg
	Map.position = new_player_pos - MINIMAP_OFFSET

func _on_update_minimap():
	Map.update_dirty_quadrants()

func _on_pre_save():
	var saved_tiles = []
	for y in range(min_y, max_y+1):
		for x in range(min_x, max_x+1):
			var t = Map.get_cell(x, y)
			if t>=0:
				saved_tiles.append([x,y,t])
	GameData.set_state("_saved_minimap", saved_tiles)

func _on_post_load():
	min_x = 999
	min_y = 999
	max_x = 0
	max_y = 0
	var tiles = GameData.get_state("_saved_minimap", [])
	for t in tiles:
		Map.set_cell(t[0], t[1], t[2])
	visible = true

func _on_finalize_load():
	_on_new_player_location(GameData.world_tile_position.x, GameData.world_tile_position.y, GameData.player_rotation)
