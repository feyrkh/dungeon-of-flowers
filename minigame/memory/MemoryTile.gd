extends Node2D

var icons
var score = 1.0 setget set_score
var flipped = false

const POSITION_OFFSET = 90

const POSITIONS = [
	[],
	[Vector2(180/2-POSITION_OFFSET, 180/2-POSITION_OFFSET)],
	[Vector2(90-POSITION_OFFSET, 40-POSITION_OFFSET), Vector2(90-POSITION_OFFSET, 140-POSITION_OFFSET)],
	[Vector2(90-POSITION_OFFSET, 40-POSITION_OFFSET), Vector2(40-POSITION_OFFSET, 140-POSITION_OFFSET), Vector2(140-POSITION_OFFSET, 140-POSITION_OFFSET)],
	[Vector2(90-POSITION_OFFSET, 40-POSITION_OFFSET), Vector2(40-POSITION_OFFSET, 90-POSITION_OFFSET), Vector2(90-POSITION_OFFSET, 140-POSITION_OFFSET), Vector2(140-POSITION_OFFSET, 90-POSITION_OFFSET)],
	[Vector2(40-POSITION_OFFSET, 40-POSITION_OFFSET), Vector2(140-POSITION_OFFSET, 40-POSITION_OFFSET), Vector2(40-POSITION_OFFSET, 140-POSITION_OFFSET), Vector2(140-POSITION_OFFSET, 140-POSITION_OFFSET)] # alternate 4-tile with icons in corners, unused currently
]

func _ready():
	if get_tree().root == get_parent():
		setup([Vector2(randi()%4, randi()%4), Vector2(randi()%4, randi()%4), Vector2(randi()%4, randi()%4), Vector2(randi()%4, randi()%4)], [], load("res://minigame/memory/tiles/tileset.png"), 0)

func flip(half_flip_speed, delay_before_flip):
	var old_front
	var new_front
	if flipped:
		old_front = $CardBack
		new_front = $CardFront
	else:
		old_front = $CardFront
		new_front = $CardBack
	if half_flip_speed != 0 and delay_before_flip != 0:
		var tween = Tween.new()
		add_child(tween)
		tween.interpolate_property(old_front, "scale", Vector2.ONE, Vector2(0, 1), half_flip_speed, 0, 2, delay_before_flip)
		tween.interpolate_property(new_front, "scale", Vector2(0, 1), Vector2.ONE, half_flip_speed, 0, 2, delay_before_flip+half_flip_speed)
		tween.start()
		flipped = !flipped
		yield(tween, "tween_all_completed")
		tween.queue_free()
	else:
		flipped = !flipped
		old_front.scale = Vector2(0, 1)
		new_front.scale = Vector2.ONE

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
	var sprites = [$CardFront/Sprite1, $CardFront/Sprite2, $CardFront/Sprite3, $CardFront/Sprite4]
	var poses = POSITIONS[good_icons.size()]
	for i in range(poses.size()):
		sprites[i].position = poses[i]
	for icon_idx in range(good_icons.size()):
		sprites[icon_idx].texture = icon_texture
		sprites[icon_idx].region_enabled = true
		sprites[icon_idx].region_rect = Rect2(icons[icon_idx]*90, Vector2(90, 90))

func get_similarity_score(expected_icons):
	var points = 0
	var expected_points = icons.size() * 2
	for i in range(icons.size()):
		var actual_icon = icons[i]
		var expected_icon = expected_icons[i]
		if actual_icon == expected_icon:
			points += 2
		elif expected_icons.has(actual_icon):
			points += 1
	return float(points) / expected_points

func set_score(_score):
	score = _score
	$CardFront/Score/Label.text = "%d%%" % (score * 100)
	$CardFront/Score.visible = true
	#$Score.modulate = lerp(Color.darkred, Color.darkgreen, score)
	# Perfect, great, good, ok, oops

func get_summary(_score):
	var summary
	if _score >= 1.0:
		summary = "Great!"
	elif _score >= 0.75:
		summary = "Good!"
	elif _score >= 0.5:
		summary = "Not Bad!"
	elif _score >= 0.25:
		summary = "Oops!"
	else:
		summary = "Yikes!"
	$CardFront/ScoreSummary.text = summary
	return summary

func get_color(_score):
	var color
	if _score >= 1.0:
		color = Color.green
	elif _score >= 0.75:
		color = Color.greenyellow
	elif _score >= 0.5:
		color = Color.orange
	elif _score >= 0.25:
		color = Color.orangered
	else:
		color = Color.red
	return color

func fade_icons(t, delay=0.5, tween=$Tween):
	tween.remove_all()
	tween.interpolate_property($CardFront/Sprite1, "modulate", Color.white, Color.transparent, t, 0, 2, delay)
	tween.interpolate_property($CardFront/Sprite2, "modulate", Color.white, Color.transparent, t, 0, 2, delay)
	tween.interpolate_property($CardFront/Sprite3, "modulate", Color.white, Color.transparent, t, 0, 2, delay)
	tween.interpolate_property($CardFront/Sprite4, "modulate", Color.white, Color.transparent, t, 0, 2, delay)
	tween.start()

func fade_score(t, delay, avg_score):
	get_summary(avg_score)
	var tween = Tween.new()
	add_child(tween)
	#var slide_dir = Vector2($CardFront/Score/Label.rect_size.x/8, $CardFront/ScoreSummary.rect_size.y - $CardFront/Score/Label.rect_size.y/3 + 5)
	#slide_dir = slide_dir.rotated(deg2rad($ScoreSummary.rect_rotation))
	#tween.interpolate_property($ScoreSummary, "rect_position", $ScoreSummary.rect_position - slide_dir, $ScoreSummary.rect_position, t, 0, 2, delay)
	#tween.interpolate_property($CardFront/Score, "position", $CardFront/Score.position, $CardFront/Score.position + slide_dir, t, 0, 2, delay)
	tween.interpolate_property($CardFront/ScoreSummary, "rect_scale", $CardFront/ScoreSummary.rect_scale, Vector2(1, 1), t, 0, 2, delay)
	tween.interpolate_property($CardFront/Score, "scale", Vector2.ZERO, Vector2(1, 1), t, 0, 2, delay)
	#tween.interpolate_property($Score, "scale", $Score.scale, Vector2(0.5, 0.5), t, 0, 2, delay)
	tween.start()

func replace_icons(tex:Texture):
	var tween := Util.one_shot_tween(self)
	tween.interpolate_property($CardFront/Sprite1, "modulate", Color.white, Color.transparent, 0.125)
	tween.interpolate_property($CardFront/Sprite2, "modulate", Color.white, Color.transparent, 0.125)
	tween.interpolate_property($CardFront/Sprite3, "modulate", Color.white, Color.transparent, 0.125)
	tween.interpolate_property($CardFront/Sprite4, "modulate", Color.white, Color.transparent, 0.125)
	tween.start()
	yield(tween, "tween_all_completed")
	$CardFront/Sprite1.position = POSITIONS[1][0]
	$CardFront/Sprite1.texture = tex
	$CardFront/Sprite1.region_enabled = false

	tween = Util.one_shot_tween(self)
	tween.interpolate_property($CardFront/Sprite1, "modulate", $CardFront/Sprite1.modulate, Color.white, 0.125)
	$CardFront/Sprite2.visible = false
	$CardFront/Sprite3.visible = false
	$CardFront/Sprite4.visible = false
	tween.start()
