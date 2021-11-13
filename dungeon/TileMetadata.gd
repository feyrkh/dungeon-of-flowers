extends Area
class_name TileMetadata

export var tile_name = "wall"
export var valid_prop_area = false
export var can_move_onto = false

func is_valid_prop_area():
	return valid_prop_area
	#return true
