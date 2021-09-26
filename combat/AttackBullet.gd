extends Node2D

var damage = 0.5
var piercing = false
var velocity
var lifetime

func setup(base_damage:float, intention_source, origin:Vector2, target:Vector2, reach_center_seconds:float, lifetime:float):
	self.damage = base_damage
	self.global_position = origin
	self.velocity = (target - origin)/reach_center_seconds
	self.lifetime = min(lifetime, 1.0)

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	self.global_position += velocity*delta
