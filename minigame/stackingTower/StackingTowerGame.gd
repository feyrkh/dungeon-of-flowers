extends Node2D

signal minigame_success(successAmount)
signal minigame_complete

const StackItem = preload("res://minigame/stackingTower/StackItem.tscn")
const MIN_STACK_Y = 800
const STACK_SINK_PER_SECOND = 400
const DANGER_ZONE_OFFSET = 30

onready var Dropper = find_node("Dropper")
onready var Stack = find_node("Stack")
onready var DangerZone = find_node("DangerZone")
var cur_item = null

var started
var path_seconds = 3.0
var down_speed = 900
var top_of_stack_y
var state = "starting"

func _ready():
	yield(get_tree().create_timer(0.5), "timeout")
	if get_parent() == get_tree().root:
		start(false)
	top_of_stack_y = find_node("StackItem").global_position.y

func start(with_tutorial=true):
	if with_tutorial and !GameData.get_state("ST_inst", false):
		EventBus.emit_signal("show_tutorial", "FirstTimeTooltip", true)
	started = true

func _physics_process(delta):
	if !started: 
		return
	if top_of_stack_y < MIN_STACK_Y:
		var sink_amt = min(delta * STACK_SINK_PER_SECOND, MIN_STACK_Y - top_of_stack_y)
		top_of_stack_y += sink_amt
		Stack.position.y += sink_amt
		DangerZone.rect_global_position.y += sink_amt
	if DangerZone.rect_global_position.y > top_of_stack_y + DANGER_ZONE_OFFSET:
		DangerZone.rect_global_position.y = max(DangerZone.rect_global_position.y - delta * STACK_SINK_PER_SECOND, top_of_stack_y + DANGER_ZONE_OFFSET)
	if state == "starting":
		Dropper.unit_offset = 0
		cur_item = StackItem.instance()
		Dropper.add_child(cur_item)
		cur_item.position = Dropper.position
		state = "moving"
		return
	if state == "moving":
		Dropper.unit_offset =  min(1.0, Dropper.unit_offset + delta / path_seconds)
		if Dropper.unit_offset >= 1.0:
			drop_item()
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

func on_stack_collide(dropped_item, stack_item:Area2D):
	var stack_rect:CollisionShape2D = stack_item.find_node("CollisionShape2D")
	var top_left = stack_rect.global_position - Vector2(stack_rect.shape.extents.x*dropped_item.scale.x, stack_rect.shape.extents.y*dropped_item.scale.y)
	var top_right = top_left + Vector2(stack_rect.shape.extents.x*2*dropped_item.scale.x, 0)
	dropped_item.land_on_stack(top_left, top_right)
	top_of_stack_y = dropped_item.global_position.y
	state = "starting"
	

func on_dangerzone_collide(dropped_item):
	state = "ending"

func set_minigame_config(game_config, source, target):
	pass
