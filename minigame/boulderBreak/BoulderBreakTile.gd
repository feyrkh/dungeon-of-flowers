extends TextureRect

var map_position
var toughness setget set_toughness
var max_toughness
var visited_for_flood_fill:bool = false

func save_data():
	return {
		'toughness': toughness,
		'max_toughness': max_toughness,
	}

func restore_data(pos, save_data):
	map_position = pos
	max_toughness = save_data.get('max_toughness', 4)
	set_toughness(save_data.get('toughness', 1))

func setup(_map_position, hash_salt, pos, _max_toughness, dist_from_center_normalized):
	map_position = _map_position
	max_toughness = _max_toughness
	var h:float = Util.hash_rand(str(pos), str(hash_salt))
	if h > 0.35:
		set_toughness(min(max_toughness, floor((1.0-dist_from_center_normalized)/(1.0/max_toughness)+1)))
	else:
		h = fmod(h * 10, 1.0)
		set_toughness(floor(h*max_toughness+1))

func set_toughness(val):
	toughness = val
	texture = preload("res://minigame/boulderBreak/stone_tile.png")
	if toughness > 0:
		modulate = Color.white.darkened((toughness-1)/(max_toughness))
	else:
		modulate = Color.transparent
	print("modulate: ", modulate)
