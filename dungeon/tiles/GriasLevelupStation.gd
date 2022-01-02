extends DisableMovementTile

const GriasLevelup = preload("res://levelup/GriasLevelup.tscn")

func _ready():
	pass

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)
	disable_movement()

func is_interactable():
	return true

func get_interactable_prompt():
	return "Meditate"

func interact():
	var levelup_screen = GriasLevelup.instance()
	get_tree().root.find_node("FullScreenOverlayContainer", true, false).add_child(levelup_screen)
