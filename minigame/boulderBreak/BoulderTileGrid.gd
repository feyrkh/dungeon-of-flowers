extends GridContainer

var tiles = {}

func generate_grid(hash_salt, grid_size, max_toughness):
	self.columns = grid_size
	var center = Vector2(grid_size/2.0 - 0.5, grid_size/2.0 - 0.5)
	var dist_to_center_from_corner = center.length()
	for y in range(grid_size):
		for x in range(grid_size):
			var pos = Vector2(x, y)
			var tile = preload("res://minigame/boulderBreak/BoulderBreakTile.tscn").instance()
			var dist_from_center_normalized = (center.distance_to(pos)/dist_to_center_from_corner)
			tile.setup(hash_salt, pos, max_toughness, dist_from_center_normalized)
			add_child(tile)
			tiles[pos] = tile

func get_tile_node_by_coords(coords:Vector2):
	return tiles[coords]

# Border index starts starts at the top of the top-left tile with idx=0. For a 4x4 tile grid, the indices look like this:
#    0  1  2  3
# 15            4
# 14            5
# 13            6
# 12            7
#    11 10 9  8
# This returns a dict like this:
# {
#  "tile_pos": <Vector2: x/y coord of the tile the tip of the cursor should be pointing at>
#  "node": <BoulderBreakTile: the actual tile node>
#  "pos": <Vector2: x/y coord of the pixel the tip of the cursor should be pointing at>
#  "rot": <int: rotation in degrees of the cursor, assuming the cursor points down by default>
#  "vec": <Vector2: direction of travel to apply swings
# }
func get_tile_by_border_index(idx:int) -> Dictionary:
	idx = idx % (self.columns * 4)
	var side = int(idx / self.columns) # 0=top, 1=right, 2=bottom, 3=left
	var side_offset = int(idx % self.columns) # how many tiles offset from the start of a side we are
	var x
	var y
	var x_pix
	var y_pix
	var rot
	var vec
	match side:
		0:
			y = 0
			x = side_offset
			x_pix = BoulderBreakGame.TILE_SIZE / 2
			y_pix = 0
			rot = 0
			vec = Vector2.DOWN
		1:
			x = self.columns - 1
			y = side_offset
			x_pix = BoulderBreakGame.TILE_SIZE
			y_pix = BoulderBreakGame.TILE_SIZE / 2
			rot = 90
			vec = Vector2.LEFT
		2:
			y = self.columns - 1
			x = self.columns - side_offset - 1
			x_pix = BoulderBreakGame.TILE_SIZE / 2
			y_pix = BoulderBreakGame.TILE_SIZE
			rot = 180
			vec = Vector2.UP
		3:
			y = self.columns - side_offset - 1
			x = 0
			x_pix = 0
			y_pix = BoulderBreakGame.TILE_SIZE / 2
			rot = 270
			vec = Vector2.RIGHT
		_:
			printerr("Bad index for get_tile_by_border_index: ", idx, "; max idx should have been ", self.columns * 4 - 1)
	var node = self.get_child(y * self.columns + x)
	return {"tile_pos":Vector2(x,y), "node": node, "pos": node.rect_global_position + Vector2(x_pix, y_pix), "rot": rot, "vec": vec}

func _ready() -> void:
	pass