extends Node2D

var target_marker
var enemy
var start_position:Vector2
var target_position:Vector2
var move_time
var t

func _ready():
	set_process(false)

func _process(delta):
	t = min(1.0, t+delta/move_time)
	self.global_position = start_position.linear_interpolate(target_position, t)
	if t >= 1.0:
		set_process(false)

func set_enemy(_enemy):
	self.enemy = _enemy

func set_target_marker(_target_marker):
	self.target_marker = _target_marker

func set_target_position(pos, _move_time):
	set_process(true)
	start_position = global_position
	target_position = pos
	self.move_time = _move_time
	self.t = 0.0
