extends Node2D

signal minigame_success(successAmount)
signal minigame_complete

const center = Vector2(295, 295)
const endpoint = Vector2(0, -(295-33))
const Target = preload("res://minigame/attackRing/Target.tscn")
const SHAKE_SIZE = 3
const SHAKE_INTERVAL = 0.05
const SHAKE_TIME = 0.5

const cursor_miss = preload("res://sound/mixkit-air-in-a-hit-2161.wav")
const cursor_weak = preload("res://sound/mixkit-metallic-sword-strike-2160.wav")
const cursor_strike = preload("res://sound/thump.mp3")
const cursor_critical = preload("res://sound/mixkit-sword-cutting-flesh-2788.wav")

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

var game_config
var ally
var enemy
var damage = 10

func _ready():
	setup(4 + GameData.get_state(GameData.ATTACK_RING_HANDICAP, 0))
	place_at(Cursor, start_degrees)
	yield(get_tree().create_timer(0.5), "timeout")
	if get_parent() == get_tree().root:
		start()
		
func start():
	started = true

func set_minigame_config(game_config, ally, enemy):
	self.game_config = game_config.duplicate(true)
	self.ally = ally
	self.enemy = enemy
	self.damage = self.game_config.get("damage", 10)

func setup(seconds_to_complete):
	Util.delete_children(Targets)
	degrees_per_second = (end_degrees - start_degrees)/seconds_to_complete
	if game_config == null:
		var offset = 0.125
		for i in range(7):
			add_target(offset, rand_range(1, 5), rand_range(6, 20), rand_range(21, 40))
			offset += 0.125
	else:
		for target_data in game_config["targets"]:
			target_data["hi"] = max(0, target_data["hi"] * (ally.ally_data.precision/float(enemy.data.parry)))
			target_data["med"] = max(1, target_data["med"] * (ally.ally_data.strength/float(enemy.data.defend)))
			target_data["low"] = max(5, target_data["low"] * (ally.ally_data.agility/float(enemy.data.dodge)))
			add_target(target_data["offset"], target_data["hi"], target_data["med"], target_data["low"])

func _physics_process(delta):
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
		return
	cur_degrees += delta * degrees_per_second
	if cur_degrees >= end_degrees:
		emit_signal("minigame_complete", self)
		if get_parent() == get_tree().root:
			setup(4 + max(-2, min(2, GameData.get_state(GameData.ATTACK_RING_HANDICAP, 0))))
			cur_degrees -= (end_degrees - start_degrees)
		else:
			started = false
			return
	place_at(Cursor, cur_degrees)

func perform_attack():
	pause_time = SHAKE_TIME
	shake_time = SHAKE_TIME
	var multiplier = Cursor.get_highest_multiplier()
	if multiplier < 0.25:
		AudioPlayerPool.play(cursor_miss)
		apply_handicap(0.1)
	elif multiplier < 0.75:
		AudioPlayerPool.play(cursor_weak)
		apply_handicap(0.05)
		emit_signal("minigame_success", ceil(multiplier * damage))
	elif multiplier < 1.25:
		AudioPlayerPool.play(cursor_strike)
		emit_signal("minigame_success", ceil(multiplier * damage))
	else:
		AudioPlayerPool.play(cursor_critical)
		apply_handicap(-0.075)
		emit_signal("minigame_success", ceil(multiplier * damage))

func apply_handicap(amt):
	GameData.set_state(GameData.ATTACK_RING_HANDICAP, max(-2, min(2, amt + GameData.get_state(GameData.ATTACK_RING_HANDICAP, 0))))
	
	
func place_at(obj, degrees):
	obj.position = center + endpoint.rotated(deg2rad(degrees))
	obj.rotation_degrees = degrees

func add_target(line_pos, hi_width, med_width, low_width):
	var degree_pos = (line_pos * (end_degrees - start_degrees)) + start_degrees
	var new_target = Target.instance()
	new_target.setup(hi_width, med_width, low_width)
	Targets.add_child(new_target)
	place_at(new_target, degree_pos)
