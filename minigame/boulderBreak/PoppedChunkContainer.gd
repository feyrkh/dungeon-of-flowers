extends Node2D

var dx
var dy
var rot

func _ready():
	rot = 30 * randf() + 30
	dx = 200 * randf() + 50
	if randf() < 0.5:
		dx = -dx
		rot = -rot
	dy = -100


func _physics_process(delta):
	rotation_degrees += rot*delta
	dy += 1200*delta
	global_position.x += dx*delta
	global_position.y += dy*delta
	if global_position.y > 2000:
		queue_free()
