extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func on_map_place(tilemap_mgr, layer_name, cell):
	pass

func get_component_label():
	return "Locked Core"
