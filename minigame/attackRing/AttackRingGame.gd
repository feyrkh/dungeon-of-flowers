extends Node2D

const center = Vector2(295, 295)
const endpoint = Vector2(0, -(295-33))
const Target = preload("res://minigame/attackRing/Target.tscn")



onready var Cursor = find_node("Cursor")

var start_degrees = -176.71791262
var end_degrees = 176.71791262
var cur_degrees = start_degrees
var degrees_per_second
var started = false
var pause_time = 0

var targets = []

func _ready():
	setup(5)
	yield(get_tree().create_timer(0.5), "timeout")
	started = true

func setup(seconds_to_complete):
	degrees_per_second = (end_degrees - start_degrees)/seconds_to_complete
	targets = [Target.instance(),Target.instance(),Target.instance(),Target.instance(),Target.instance()]
	targets[0].setup(1, 10, 30)
	var offset = 45
	for target in targets:
		$Targets.add_child(target)
		place_at(target, -180 + offset)
		offset += 45

func _process(delta):
	if !started:
		return
	if pause_time > 0:
		pause_time -= delta
		return
	if Input.is_action_just_pressed("ui_accept"):
		pause_time = 1.0
	cur_degrees += delta * degrees_per_second
	if cur_degrees >= end_degrees:
		cur_degrees -= (end_degrees - start_degrees)
	place_at(Cursor, cur_degrees)

func place_at(obj, degrees):
	obj.position = center + endpoint.rotated(deg2rad(degrees))
	obj.rotation_degrees = degrees
