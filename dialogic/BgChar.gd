extends Node2D

onready var sprite = $Sprite
var img_path:String
var pos = "right"
var flipped = false
var target_position
var pos_offset = Vector2.ZERO
var target_position_offset_widths = 1

var pixels_per_sec = 100
var pause_interval_sec = 1.0
var pause_length_sec = 0.25
var counter = pause_interval_sec
var is_pausing = false

func _ready():
	sprite.texture = load(img_path)
	set_process(false)
	if pos == "right":
		position = Vector2(1920+pos_offset.x, 1080-sprite.texture.get_height()+pos_offset.y)
		flipped = true
	elif pos == "sneakright": 
		position = Vector2(1920+pos_offset.x, 1080-sprite.texture.get_height()+pos_offset.y)
		target_position = position - Vector2(sprite.texture.get_width() * target_position_offset_widths, 0)
		flipped = false
		set_process(true)
	elif pos == "sneakleft": 
		position = Vector2(0, 1080-sprite.texture.get_height()+pos_offset.y)
		target_position = Vector2(sprite.texture.get_width() * target_position_offset_widths, 0)
		flipped = true
		set_process(true)
	if flipped:
		sprite.scale.x = -sprite.scale.x
		
func _process(delta):
	if is_pausing:
		counter -= delta
		if counter <= 0:
			counter = pause_interval_sec
			is_pausing = false
	else:
		counter -= delta
		if counter <= 0:
			counter = pause_length_sec
			is_pausing = true
		perform_move(delta)

func perform_move(delta):
	if pos == "sneakright":
		position.x = max(position.x - delta*pixels_per_sec, target_position.x)
		if position.x == target_position.x:
			set_process(false)
	if pos == "sneakleft":
		position.x = min(position.x + delta*pixels_per_sec, target_position.x)
		if position.x == target_position.x:
			set_process(false)
