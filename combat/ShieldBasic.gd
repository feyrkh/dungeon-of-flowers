extends Node2D
class_name ShieldBasic

const SCREEN_WIDTH = 1920
const NORMAL_VELOCITY = 100
const SPRINT_VELOCITY = 300

var dash_time = 0
var dash_cooldown = 0
var dash_direction = 0

var shield_data:Dictionary
var speed_bonus = 1.0

func _physics_process(delta):
	if !visible:
		return
	if dash_cooldown > 0:
		dash_cooldown -= delta
	if dash_time <= 0:
		if Input.is_action_pressed("ui_left"):
			if Input.is_action_pressed("sprint") and shield_data.get("shield_dash") and dash_cooldown <= 0 and dash_time <= 0:
				dash_time = 0.3
				dash_direction = -1
			else:
				global_position.x -= NORMAL_VELOCITY * delta * speed_bonus
		elif Input.is_action_pressed("ui_right"):
			if Input.is_action_pressed("sprint") and shield_data.get("shield_dash") and dash_cooldown <= 0 and dash_time <= 0:
				dash_time = 0.3
				dash_direction = -1
			else:
				global_position.x += NORMAL_VELOCITY * delta * speed_bonus
	if dash_time > 0:
		dash_time -= delta
		global_position.x += SPRINT_VELOCITY * delta * speed_bonus * dash_direction
		if dash_time < 0:
			dash_cooldown = 1
	if global_position.x < 0:
		global_position.x += SCREEN_WIDTH
	elif global_position.x > SCREEN_WIDTH:
		global_position.x -= SCREEN_WIDTH
