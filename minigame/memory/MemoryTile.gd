extends Node2D

var icons

const POSITIONS = [
	[], 
	[Vector2(180/2, 180/2)], 
	[Vector2(90, 40), Vector2(90, 140)], 
	[Vector2(90, 40), Vector2(40, 140), Vector2(140, 140)],
	[Vector2(90, 40), Vector2(40, 90), Vector2(90, 140), Vector2(140, 90)],
	[Vector2(40, 40), Vector2(140, 40), Vector2(40, 140), Vector2(140, 140)] # alternate 4-tile with icons in corners, unused currently
] 

func setup(good_icons:Array, bad_icons:Array, icon_texture:Texture, badness:int):
	icons = good_icons.duplicate()
	var icon_badness = range(good_icons.size())
	icon_badness.shuffle()
	bad_icons.shuffle()
	var bad_icons_used = 0
	while badness > 1 and bad_icons_used < good_icons.size():
		icons[icon_badness[bad_icons_used]] = bad_icons[bad_icons_used]
		badness -= 2
		bad_icons_used += 1
	if badness > 0 and bad_icons_used < good_icons.size()-1:
		var swap_idx = icon_badness[bad_icons_used]
		var swap_with = swap_idx
		while swap_with == swap_idx:
			swap_with = randi()%good_icons.size()
		var swap = icons[swap_idx]
		icons[swap_idx] = icons[swap_with]
		icons[swap_with] = swap
	var sprites = [$Sprite1, $Sprite2, $Sprite3, $Sprite4]
	var poses = POSITIONS[good_icons.size()]
	for i in range(poses.size()):
		sprites[i].position = poses[i] 
	for icon_idx in range(good_icons.size()):
		sprites[icon_idx].texture = icon_texture
		sprites[icon_idx].region_enabled = true
		sprites[icon_idx].region_rect = Rect2(icons[icon_idx]*90, Vector2(90, 90))
		
