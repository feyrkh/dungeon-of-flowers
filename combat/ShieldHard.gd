extends Node2D

const SCREEN_WIDTH = 1920
const NORMAL_VELOCITY = 200
const SPRINT_VELOCITY = 100
const KNOCKBACK_SIDE_PIXELS = 50 # pixels moved left/right on blocked hit

var shield_data:Dictionary
var speed_bonus = 1.0

func setup(ally, _shield_data):
	self.shield_data = _shield_data
	global_position = ally.get_target(0) + shield_data.get("pos", Vector2.ZERO)
	scale = shield_data.get("shield_size", Vector2.ONE)
	speed_bonus = shield_data.get("shield_speed", 1.0)
	get_weakness()

func _physics_process(delta):
	if !visible:
		return
	if Input.is_action_pressed("ui_left"):
		if !Input.is_action_pressed("sprint"):
			global_position.x -= SPRINT_VELOCITY * delta * speed_bonus
		else:
			global_position.x -= NORMAL_VELOCITY * delta * speed_bonus
	elif Input.is_action_pressed("ui_right"):
		if !Input.is_action_pressed("sprint"):
			global_position.x += SPRINT_VELOCITY * delta * speed_bonus
		else:
			global_position.x += NORMAL_VELOCITY * delta * speed_bonus
	if global_position.x < 0:
		global_position.x += SCREEN_WIDTH
	elif global_position.x > SCREEN_WIDTH:
		global_position.x -= SCREEN_WIDTH

func get_weakness():
	var weakness_ratio = float(shield_data.get("shield_damage", 0)) / shield_data.get("shield_strength", 12)
	self.modulate = Color(1.0, 1.0-weakness_ratio, 1.0-weakness_ratio)
	return weakness_ratio

func _on_Area2D_body_entered(bullet:Node2D):
	bullet.shield_block(self)
	shield_data["shield_damage"] = min(shield_data.get("shield_strength", 12), shield_data.get("shield_damage", 0)+1)
	var weakness_ratio = get_weakness()
	var offset_dir = bullet.global_position.x < global_position.x
	if !offset_dir: offset_dir = -1
	else: offset_dir = 1
	#global_position.y += KNOCKBACK_DOWN_PIXELS * weakness_ratio
	position.x += KNOCKBACK_SIDE_PIXELS * weakness_ratio * offset_dir
