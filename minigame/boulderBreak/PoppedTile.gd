extends Sprite


func destroy_tile(rseed:float, origin_tile:TextureRect):
	global_position = origin_tile.rect_global_position
	texture = origin_tile.texture
	modulate = origin_tile.modulate
	print("Placed popped tile at ", global_position)
