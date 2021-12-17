extends Node2D

const colors = [Color.white, Color.yellow, Color.brown, Color.blue, Color.black]

onready var img = $Sprite

var cur_color = 0
var next_color = 1
var counter = 0

func _process(delta):
	counter += delta
	if counter > 1:
		counter -= 1
		cur_color = (cur_color + 1) % colors.size()
		next_color = (cur_color + 1) % colors.size()
	img.modulate = lerp(colors[cur_color], colors[next_color], counter)

func show_rotation_icon(enabled):
	$rotate_right.visible = enabled
	$rotate_right/rotate_right.visible = enabled
	$rotate_left.visible = enabled
	$rotate_left/rotate_left.visible = enabled

func perform_rotation(dir):
	var tween:Tween
	var icon
	if dir < 0:
		tween = $LeftTween
		icon = $rotate_left
	else:
		tween = $RightTween
		icon = $rotate_right
	if tween.is_active():
		tween.stop_all()
	tween.interpolate_property(icon, "modulate", Color.yellow, Color.white, 0.5)
	tween.start()
