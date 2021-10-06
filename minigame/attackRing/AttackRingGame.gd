extends Node2D

const center = Vector2(295, 295)
const endpoint = Vector2(0, -(295-33))
const Target = preload("res://minigame/attackRing/Target.tscn")
const SHAKE_SIZE = 3
const SHAKE_INTERVAL = 0.05

const cursor_strike = preload("res://sound/mixkit-sword-cutting-flesh-2788.wav")

onready var Cursor = find_node("Cursor")
onready var Targets = find_node("Targets")
onready var Shaker = find_node("Shaker")

var start_degrees = -176.71791262
var end_degrees = 176.71791262
var cur_degrees = start_degrees
var degrees_per_second
var started = false
var pause_time = 0
var shake_time = 0
var shake_counter = 0

var targets = []

func _ready():
	setup(5)
	yield(get_tree().create_timer(0.5), "timeout")
	started = true

func setup(seconds_to_complete):
	degrees_per_second = (end_degrees - start_degrees)/seconds_to_complete
	var offset = 0.125
	for i in range(6):
		add_target(offset, rand_range(1, 5), rand_range(10, 20), rand_range(25, 40))
		offset += 0.125

func _process(delta):
	if !started:
		return
	if shake_time > 0:
		shake_counter += delta
		shake_time -= delta
		if shake_counter >= SHAKE_INTERVAL:
			Shaker.position = Vector2(rand_range(-SHAKE_SIZE, SHAKE_SIZE), rand_range(-SHAKE_SIZE, SHAKE_SIZE))
			shake_counter -= SHAKE_INTERVAL
		if shake_time <= 0:
			Shaker.position = Vector2.ZERO
	if pause_time > 0:
		pause_time -= delta
		return
	if Input.is_action_just_pressed("ui_accept"):
		perform_attack()
	cur_degrees += delta * degrees_per_second
	if cur_degrees >= end_degrees:
		cur_degrees -= (end_degrees - start_degrees)
	place_at(Cursor, cur_degrees)

func perform_attack():
	pause_time = 0.5
	shake_time = 0.5
	AudioPlayerPool.play(cursor_strike)
	
func place_at(obj, degrees):
	obj.position = center + endpoint.rotated(deg2rad(degrees))
	obj.rotation_degrees = degrees

func add_target(line_pos, hi_width, med_width, low_width):
	var degree_pos = (line_pos * (end_degrees - start_degrees)) + start_degrees
	var new_target = Target.instance()
	new_target.setup(hi_width, med_width, low_width)
	Targets.add_child(new_target)
	place_at(new_target, degree_pos)
