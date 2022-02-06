extends DisableMovementTile

onready var TileMetadata = find_node("TileMetadata", true, false)

var map_coords

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)
	map_coords = cell

func _ready():
	TileMetadata.find_node("CollisionShape").disabled = true
	EventBus.connect("player_finish_move", self, "spawn_pollen")

func spawn_pollen():
	if randf() < 0.075:
		EventBus.emit_signal("spawn_pollen", map_coords)
