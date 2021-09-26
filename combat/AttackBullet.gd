extends Node2D

var damage = 0.5
var piercing = false
var velocity
var lifetime

func setup(base_damage:float, intention_source, origin:Vector2, target:Vector2, reach_center_seconds:float, _lifetime:float):
	rotation = origin.angle_to_point(target)
	self.damage = base_damage
	self.global_position = origin
	self.velocity = (target - origin)/reach_center_seconds
	self.lifetime = max(_lifetime, 1.0)
	#var debug_line = Line2D.new()
	#debug_line.add_point(origin)
	#debug_line.add_point(target)
	#debug_line.width = 1
	#get_parent().add_child(debug_line)

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		print("finishing at ", self.global_position)
		queue_free()
	self.global_position += velocity*delta
