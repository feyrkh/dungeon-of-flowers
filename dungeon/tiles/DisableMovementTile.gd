extends DungeonEntity
class_name DisableMovementTile

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)
	disable_movement(true)

func disable_movement(do_disable=true):
	if dungeon:
		var corridor = dungeon.get_tile_scene("ground", map_position)
		var metadata:TileMetadata = corridor.find_node("TileMetadata")
		metadata.can_move_onto = !do_disable
