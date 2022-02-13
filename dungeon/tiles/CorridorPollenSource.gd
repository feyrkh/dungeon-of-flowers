extends DisableMovementTile

onready var TileMetadata = find_node("TileMetadata", true, false)
var destroyed = false

func post_config(map_config):
	if destroyed:
		queue_free()

func pre_save_game():
	update_config({"destroyed":destroyed})

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)

func _ready():
	TileMetadata.find_node("CollisionShape").disabled = true
	EventBus.connect("player_finish_move", self, "spawn_pollen")

func spawn_pollen():
	if randf() < 0.075:
		EventBus.emit_signal("spawn_pollen", map_position)

func is_interactable():
	return !destroyed

func get_interactable_prompt():
	return "Destroy"

func count_adjacent_vines():
	var adjacent_vines = 0
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var adjacent_vine = dungeon.get_tile_scene("floor_overlay", map_position + dir)
		if adjacent_vine and is_instance_valid(adjacent_vine) and adjacent_vine.has_method("destroy_vines"):
			adjacent_vines += 1
	return adjacent_vines

func interact():
	var adjacent_vines = count_adjacent_vines()
	if adjacent_vines > 0:
		AudioPlayerPool.play("res://sound/sword-block.wav")
		EventBus.emit_signal("start_chat", "pollen_spawn_protected")
	else:
		disable_movement(false)
		destroyed = true
		change_tile(-1)
		queue_free()
		AudioPlayerPool.play("res://sound/combat-strike.mp3")
		EventBus.emit_signal("start_chat", "pollen_spawn_destroyed")

func destroy_vines():
	pass
