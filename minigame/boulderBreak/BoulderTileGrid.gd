extends GridContainer

signal rotation_complete

const ROTATIONS = [0, 270, 180, 90]

# changes when rotating, index into DOWN_VECTORS and ROTATIONS - Vector2.LEFT means that moving left will bring the chisel closer to the boulder
var down_vector_idx:int = 0
var tiles = {}
var tween:Tween

func generate_grid(hash_salt, grid_size, max_toughness):
	self.columns = grid_size
	var center = Vector2(grid_size/2.0 - 0.5, grid_size/2.0 - 0.5)
	var dist_to_center_from_corner = center.length()
	for y in range(grid_size):
		for x in range(grid_size):
			var pos = Vector2(x, y)
			var tile = preload("res://minigame/boulderBreak/BoulderBreakTile.tscn").instance()
			var dist_from_center_normalized = (center.distance_to(pos)/dist_to_center_from_corner)
			tile.setup(pos, hash_salt, pos, max_toughness, dist_from_center_normalized)
			add_child(tile)
			tiles[pos] = tile

func get_tile_node_by_coords(coords:Vector2):
	return tiles.get(coords, null)

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
			if side_offset == 0:
				rot = 360
			else:
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
	tween = Tween.new()
	get_parent().call_deferred("add_child", tween)


func destroy_small_chunks():
	var min_chunk_size = floor((columns * columns)/6) + 1
	var unvisited_tiles = tiles.values()
	var cur_visited_tiles = []
	for tile in unvisited_tiles:
		tile.visited_for_flood_fill = false
	while unvisited_tiles.size() > 0:
		var cur_tile = unvisited_tiles.pop_back()
		if cur_tile.toughness <= 0:
			continue
		cur_visited_tiles = []
		flood_fill(cur_tile, unvisited_tiles, cur_visited_tiles)
		if cur_visited_tiles.size() <= min_chunk_size:
			print("Destroying ", cur_visited_tiles.size(), " tiles")
			destroy_tiles(cur_visited_tiles)

func destroy_tiles(tile_list):
	var rseed = randf()
	var chunk = preload("res://minigame/boulderBreak/PoppedChunkContainer.tscn").instance()
	var pos = Vector2.ZERO
	for tile in tile_list:
		pos += tile.rect_global_position
	pos /= tile_list.size()
	chunk.global_position = pos
	get_parent().get_node("PoppedTileContainer").add_child(chunk)
	for tile in tile_list:
		var popped_tile = preload("res://minigame/boulderBreak/PoppedTile.tscn").instance()
		chunk.add_child(popped_tile)
		popped_tile.destroy_tile(rseed, tile)
		tile.toughness = 0
	pass

func flood_fill(cur_tile, unvisited_tiles, cur_visited_tiles):
	if cur_tile == null or cur_tile.visited_for_flood_fill:
		return
	cur_tile.visited_for_flood_fill = true
	unvisited_tiles.erase(cur_tile)
	if cur_tile.toughness <= 0:
		return
	cur_visited_tiles.push_back(cur_tile)
	flood_fill(get_tile_node_by_coords(cur_tile.map_position + Vector2.UP), unvisited_tiles, cur_visited_tiles)
	flood_fill(get_tile_node_by_coords(cur_tile.map_position + Vector2.DOWN), unvisited_tiles, cur_visited_tiles)
	flood_fill(get_tile_node_by_coords(cur_tile.map_position + Vector2.LEFT), unvisited_tiles, cur_visited_tiles)
	flood_fill(get_tile_node_by_coords(cur_tile.map_position + Vector2.RIGHT), unvisited_tiles, cur_visited_tiles)

func rotate_grid(dir):
	tween.stop_all()
	down_vector_idx = posmod(down_vector_idx-dir, 4)
	if rect_rotation <= 90 and ROTATIONS[down_vector_idx] > 180:
		rect_rotation = rect_rotation + 360
	elif rect_rotation >= 270 and ROTATIONS[down_vector_idx] < 90:
		rect_rotation -= 360
	tween.interpolate_property(self, "rect_rotation", self.rect_rotation, ROTATIONS[down_vector_idx], 0.25)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("rotation_complete")




func _on_BoulderTileGrid_resized() -> void:
	rect_pivot_offset = rect_size/2.0
