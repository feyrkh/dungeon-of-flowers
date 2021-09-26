extends Node2D

const SCREEN_WIDTH = 1920
const NORMAL_VELOCITY = 150
const SPRINT_VELOCITY = 300

func setup(ally, shield_data):
	global_position = ally.get_target(0) + shield_data.get("pos", Vector2.ZERO)
	scale = shield_data.get("scale", Vector2.ONE)

func _physics_process(delta):
	if Input.is_action_pressed("ui_left"):
		if !Input.is_action_pressed("sprint"):
			global_position.x -= SPRINT_VELOCITY * delta
		else:
			global_position.x -= NORMAL_VELOCITY * delta
	elif Input.is_action_pressed("ui_right"):
		if !Input.is_action_pressed("sprint"):
			global_position.x += SPRINT_VELOCITY * delta
		else:
			global_position.x += NORMAL_VELOCITY * delta
	if global_position.x < 0:
		global_position.x += SCREEN_WIDTH
	elif global_position.x > SCREEN_WIDTH:
		global_position.x -= SCREEN_WIDTH


func _on_Area2D_body_entered(bullet):
	bullet.shield_block(self)
