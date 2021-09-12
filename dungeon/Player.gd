extends Spatial

const ROTATE_TIME = 0.5
const MOVE_TIME = 0.5

var is_moving = false
var start_rotation
var target_rotation
var start_position
var target_position
var rotation_time
var move_time

func _ready():
	transform = transform.looking_at(transform.origin + Vector3(0, 0, 1), Vector3.UP)

func _input(event):
	if is_moving: 
		return
	if event.is_action_pressed("move_forward"):
		move(1)
	elif event.is_action_pressed("move_backward"):
		move(-1)
	if event.is_action_pressed("move_left"):
		sidestep(1)
	elif event.is_action_pressed("move_right"):
		sidestep(-1)
	elif event.is_action_pressed("turn_left"):
		turn(-1)
	elif event.is_action_pressed("turn_right"):
		turn(1)

func _process(delta):
	if target_position:
		move_time += delta
		if move_time < MOVE_TIME:
			global_transform.origin = (target_position - start_position)*(move_time/MOVE_TIME)+start_position
		else:
			global_transform.origin = target_position
			target_position = null
			move_time = 0
			is_moving = false
			print("ended move at ", OS.get_system_time_msecs())
	if target_rotation:
		rotation_time += delta
		if rotation_time < ROTATE_TIME:
			transform.basis = start_rotation.slerp(target_rotation, rotation_time/ROTATE_TIME)
		else:
			transform.basis = target_rotation
			target_rotation = null
			rotation_time = 0
			is_moving = false
			print("ended rotate at ", OS.get_system_time_msecs())

func move(dir):
	if is_moving: 
		return
	is_moving = true
	print("start move at ", OS.get_system_time_msecs())
	start_position = global_transform.origin
	target_position = global_transform.origin + global_transform.basis.z*3 * -dir
	move_time = 0

func sidestep(dir):
	if is_moving:
		return
	is_moving = true
	print("start sidestep at ", OS.get_system_time_msecs())
	start_position = global_transform.origin
	target_position = global_transform.origin + global_transform.basis.x*3*-dir
	move_time = 0

func turn(dir):
	if is_moving: 
		return
	is_moving = true
	print("start rotate at ", OS.get_system_time_msecs())
	start_rotation = transform.basis
	target_rotation = transform.basis.rotated(Vector3.DOWN, deg2rad(90*dir))
	rotation_time = 0
