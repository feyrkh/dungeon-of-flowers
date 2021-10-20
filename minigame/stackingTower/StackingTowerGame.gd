extends Node2D

signal minigame_success(successAmount)
signal minigame_complete

const StackItem = preload("res://minigame/stackingTower/StackItem.tscn")
const MIN_STACK_Y = 800
const STACK_SINK_PER_SECOND = 400
const ALPHA_SINK_PER_SECOND = 0.3
const DANGER_ZONE_OFFSET = 30+75
const DANGER_ZONE_INCREASE = 70

onready var Dropper = find_node("Dropper")
onready var Stack = find_node("Stack")
onready var DangerZone = find_node("DangerZone")
onready var HighScoreLine = find_node("HighScoreLine")
onready var TargetGuide = find_node("TargetGuide")
onready var AimGuide = find_node("AimGuide")
var cur_item = null

var started
var path_seconds = 3.0
var down_speed = 900
var top_of_stack_y
var state = "starting"
var target_alpha = 0.8
var tops = {}
var danger_zone_target

var source
var target
var game_config

func _ready():
	top_of_stack_y = find_node("StackItem").global_position.y
	update_target_guide(find_node("StackItem"))
	yield(get_tree().create_timer(0.5), "timeout")
	if get_parent() == get_tree().root:
		set_minigame_config({
			"rewards": [
				"shield size ++",
				"shield speed ++",
				"sturdiness +5",
				"team armor +1",
				"stamina regen",
				"shields +1",
			],
			"rewardInterval": 1.8
		}, null, null)
		start(false)
	for child in Stack.get_children():
		tops[child.bonus_type] = child.global_position.y
	danger_zone_target = 1079
		
func start(with_tutorial=true):
	if with_tutorial and !GameData.get_state("ST_inst", false):
		EventBus.emit_signal("show_tutorial", "FirstTimeTooltip", true)
	started = true

func _physics_process(delta):
	if !started: 
		return
	if DangerZone.rect_position.y != danger_zone_target:
		DangerZone.rect_position.y = lerp(DangerZone.rect_position.y, danger_zone_target, delta)
	HighScoreLine.position.y = top_of_stack_y
	if TargetGuide.modulate.a > target_alpha:
		TargetGuide.modulate.a = max(target_alpha, TargetGuide.modulate.a - delta*ALPHA_SINK_PER_SECOND)
	if top_of_stack_y < MIN_STACK_Y:
		var sink_amt = min(delta * STACK_SINK_PER_SECOND, MIN_STACK_Y - top_of_stack_y)
		top_of_stack_y += sink_amt
		Stack.position.y += sink_amt
		DangerZone.rect_global_position.y += sink_amt
		danger_zone_target += sink_amt
		for k in tops.keys():
			tops[k] += sink_amt
	#if DangerZone.rect_global_position.y > top_of_stack_y + DANGER_ZONE_OFFSET:
	#	DangerZone.rect_global_position.y = max(DangerZone.rect_global_position.y - delta * STACK_SINK_PER_SECOND, top_of_stack_y + DANGER_ZONE_OFFSET)
	if DangerZone.rect_global_position.y < top_of_stack_y:
		drop_item()
	if danger_zone_target > 1079:
		danger_zone_target = 1079
	if state == "starting":
		Dropper.unit_offset = 0
		cur_item = StackItem.instance()
		Dropper.add_child(cur_item)
		#cur_item.position = Dropper.position
		state = "moving"
		#TargetGuide.visible = true
		AimGuide.visible = true
		danger_zone_target -= DANGER_ZONE_INCREASE/get_stacks_above_danger()
		#DangerZone.rect_global_position.y -= DANGER_ZONE_INCREASE/get_stacks_above_danger()
		return
	if state == "moving":
		Dropper.unit_offset =  min(1.0, Dropper.unit_offset + delta / path_seconds)
		if Dropper.unit_offset >= 1.0:
			#drop_item()
			Dropper.unit_offset = 0
			danger_zone_target -= floor(DANGER_ZONE_INCREASE/2/get_stacks_above_danger())
		elif Input.is_action_just_pressed("ui_accept"):
			drop_item()
		return
	if state == "drop":
		cur_item.position.y += delta * down_speed
		return
	if state == "ending":
		set_process(false)
		yield(get_tree().create_timer(0.5), "timeout")
		emit_signal("minigame_complete", self)

func get_stacks_above_danger():
	var result = 0
	for k in tops.keys():
		if tops[k] < DangerZone.rect_global_position.y:
			result += 1
	return result

func drop_item():
	state = "drop"
	cur_item.global_position.x = round(cur_item.global_position.x)
	var pos = cur_item.global_position
	Dropper.remove_child(cur_item)
	Stack.add_child(cur_item)
	cur_item.global_position = pos
	Dropper.unit_offset = 0
	cur_item.connect("stack_collide", self, "on_stack_collide")
	cur_item.connect("dangerzone_collide", self, "on_dangerzone_collide")
	path_seconds = path_seconds * 0.9
	target_alpha = max(0, TargetGuide.modulate.a - 0.3)
	TargetGuide.visible = false
	AimGuide.modulate.a = max(0, AimGuide.modulate.a - 0.33)
	AimGuide.visible = false

func on_stack_collide(dropped_item, stack_item:Area2D):
	dropped_item.disconnect("stack_collide", self, "on_stack_collide")
	dropped_item.disconnect("dangerzone_collide", self, "on_dangerzone_collide")
	var stack_rect:CollisionShape2D = stack_item.find_node("CollisionShape2D")
	var top_left = stack_rect.global_position - Vector2(stack_rect.shape.extents.x*dropped_item.scale.x, stack_rect.shape.extents.y*dropped_item.scale.y)
	var top_right = top_left + Vector2(stack_rect.shape.extents.x*2*dropped_item.scale.x, 0)
	dropped_item.land_on_stack(top_left, top_right, stack_item.get_parent().bonus_type)
	#update_target_guide(dropped_item)
	var old_top = tops.get(stack_item.get_parent().bonus_type, 1800)
	if dropped_item.global_position.y <= old_top:
		tops[stack_item.get_parent().bonus_type] = dropped_item.global_position.y;
	#if dropped_item.global_position.y < top_of_stack_y:
	top_of_stack_y = dropped_item.global_position.y
	state = "starting"

func update_target_guide(dropped_item):
	TargetGuide.rect_position.x = dropped_item.find_node("ColorRect").rect_global_position.x
	TargetGuide.rect_size.x = dropped_item.find_node("ColorRect").rect_size.x * dropped_item.scale.x
	#TargetGuide.rect_size.x = dropped_item.find_node("ColorRect").rect_size.x * dropped_item.scale.x

func on_dangerzone_collide(dropped_item):
	dropped_item.disconnect("stack_collide", self, "on_stack_collide")
	dropped_item.disconnect("dangerzone_collide", self, "on_dangerzone_collide")
	state = "ending"
	dropped_item.shatter_left(dropped_item.find_node("CollisionShape2D").shape.extents.x*dropped_item.scale.x)
	dropped_item.shatter_right(dropped_item.find_node("CollisionShape2D").shape.extents.x*dropped_item.scale.x)
	dropped_item.queue_free()

func set_minigame_config(_game_config, _source, _target):
	source = _source
	target = _target
	game_config = _game_config
