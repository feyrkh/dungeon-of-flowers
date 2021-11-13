extends Spatial
class_name DisableMovementTile

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	var corridor = dungeon.get_tile_scene("ground", cell)
	var metadata:TileMetadata = corridor.find_node("TileMetadata")
	metadata.can_move_onto = false
