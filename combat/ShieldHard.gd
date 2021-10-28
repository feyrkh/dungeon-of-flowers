extends ShieldBasic
class_name ShieldHard

const KNOCKBACK_SIDE_PIXELS = 50 # pixels moved left/right on blocked hit

func setup(ally, _shield_data):
	self.shield_data = _shield_data
	global_position = ally.get_target(0) + shield_data.get("pos", Vector2.ZERO)
	scale = Vector2(shield_data.get("shield_size", 1), shield_data.get("shield_size", 1))
	speed_bonus = shield_data.get("shield_speed", 1.0)
	get_weakness()

func get_weakness():
	var weakness_ratio = float(shield_data.get("shield_damage", 0)) / shield_data.get("shield_strength", 12)
	self.modulate = Color(1.0, 1.0-weakness_ratio, 1.0-weakness_ratio)
	return weakness_ratio

func _on_Area2D_body_entered(bullet:Node2D):
	bullet.shield_block(self, 10000)
	shield_data["shield_damage"] = min(shield_data.get("shield_strength", 12), shield_data.get("shield_damage", 0)+1)
	if shield_data.get("shield_damage", 0) >= shield_data.get("shield_strength"):
		shield_data["shield_destroyed"] = true
	var weakness_ratio = get_weakness()
	var offset_dir = bullet.global_position.x < global_position.x
	if !offset_dir: offset_dir = -1
	else: offset_dir = 1
	#global_position.y += KNOCKBACK_DOWN_PIXELS * weakness_ratio
	position.x += KNOCKBACK_SIDE_PIXELS * weakness_ratio * offset_dir

func shield_persists_between_rounds():
	return shield_data.get("shield_strength", 12) > shield_data.get("shield_damage", 0)
