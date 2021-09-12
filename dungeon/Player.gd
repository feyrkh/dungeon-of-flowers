extends Spatial

signal move_complete
signal turn_complete

const ROTATE_TIME = 0.5
const MOVE_TIME = 0.5

var is_moving = false
var start_rotation
var target_rotation
var start_position
var target_position
var rotation_time
var move_time
var move_multiplier = 1.0

onready var forwardSensor:Area = find_node("forwardSensor")
onready var backwardSensor:Area = find_node("backwardSensor")
onready var leftSensor:Area = find_node("leftSensor")
onready var rightSensor:Area = find_node("rightSensor")
onready var wallBumpSfx:AudioStreamPlayer = find_node("wallBumpSfx")

func _ready():
	transform = transform.looking_at(transform.origin + Vector3(0, 0, 1), Vector3.UP)

func _input(event):
	if is_moving: 
		return
	if event.is_action_pressed("move_forward"):
		if can_move(forwardSensor):
			move(1)
		else:
			bump_forward(1)
	elif event.is_action_pressed("move_backward"):
		if can_move(backwardSensor):
			move(-1)
		else:
			bump_forward(-1)
	if event.is_action_pressed("move_left"):
		if can_move(leftSensor):
			sidestep(1)
		else:
			bump_sideways(1)
	elif event.is_action_pressed("move_right"):
		if can_move(rightSensor):
			sidestep(-1)
		else:
			bump_sideways(-1)
	elif event.is_action_pressed("turn_left"):
		turn(-1)
	elif event.is_action_pressed("turn_right"):
		turn(1)

func bump_forward(dir):
	move_multiplier = 2
	move(0.1*dir)
	yield(self, "move_complete")
	wallBumpSfx.pitch_scale = randf()*0.3 + 0.85
	wallBumpSfx.play()
	move(-0.1*dir)
	yield(self, "move_complete")
	move_multiplier = 1

func bump_sideways(dir):
	move_multiplier = 2
	sidestep(0.1*dir)
	yield(self, "move_complete")
	wallBumpSfx.pitch_scale = randf()*0.3 + 0.85
	wallBumpSfx.play()
	sidestep(-0.1*dir)
	yield(self, "move_complete")
	move_multiplier = 1

func can_move(sensor):
	var areas = sensor.get_overlapping_areas()
	if areas.size() == 0:
		print("Can't move, no open space ahead")
		return false
	else:
		print(areas.size(), " areas overlapping")
		for area in areas:
			print(area.name)
		return true

func _process(delta):
	if target_position:
		move_time += delta*move_multiplier
		if move_time < MOVE_TIME:
			global_transform.origin = (target_position - start_position)*(move_time/MOVE_TIME)+start_position
		else:
			global_transform.origin = target_position
			target_position = null
			move_time = 0
			is_moving = false
			emit_signal("move_complete")
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
			emit_signal("turn_complete")
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
