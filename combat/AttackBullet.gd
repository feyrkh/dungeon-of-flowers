extends KinematicBody2D
class_name AttackBullet

var damage = 0.5
var piercing = false
var velocity
var rot_velocity = 0
var fade_velocity = 0
var lifetime = 10
var blocked = false

func setup(base_damage:float, _lifetime:float):
	#rotation = origin.angle_to_point(target)
	self.damage = base_damage

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		#print("finishing at ", self.global_position)
		queue_free()
	self.global_position += velocity*delta
	if rot_velocity != null:
		self.rotation_degrees += rot_velocity*delta
	if fade_velocity != null:
		self.modulate.a -= fade_velocity * delta
		if self.modulate.a <= 0:
			self.lifetime = 0

func disable_collision():
	self.collision_layer = 0
	self.collision_mask = 0

func shield_block(shield):
	if blocked: 
		return
	disable_collision()
	blocked = true
	CombatMgr.emit_signal("attack_bullet_block")
	velocity.y = -velocity.y
	rot_velocity = 600 - rand_range(0, 1200)
	fade_velocity = 1.0

func ally_strike(ally_data):
	disable_collision()
	self.velocity = Vector2.ZERO
	self.blocked = true
	self.fade_velocity = 1
	CombatMgr.emit_signal("combat_animation", 1.0)
	
func get_damage():
	return damage

func setup_bullet_motion(origin_pos, target_pos, speed):
	self.global_position = origin_pos
	self.velocity = (target_pos - origin_pos).normalized() * speed
