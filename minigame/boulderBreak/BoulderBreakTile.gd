extends TextureRect

var toughness

func setup(hash_salt, pos, max_toughness, dist_from_center_normalized):
	var h:float = Util.hash_rand(str(pos), str(hash_salt))
	if h > 0.35:
		toughness = min(max_toughness, floor((1.0-dist_from_center_normalized)/(1.0/max_toughness)+1))
	else:
		h = fmod(h * 10, 1.0)
		toughness = floor(h*max_toughness+1)
#	var toughness_accum = toughness_step
#	toughness = 1
#	while h > toughness_accum and toughness < max_toughness:
#		toughness += 1
#		toughness_accum += toughness_step
	texture = preload("res://minigame/boulderBreak/stone_tile.png")
	modulate = Color.white.darkened((toughness-1)/(max_toughness))
