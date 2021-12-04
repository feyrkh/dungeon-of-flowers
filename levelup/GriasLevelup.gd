extends Node2D

const INACTIVE = 0
const CURSOR = 1
const COMPONENT = 2
const CURSOR_OVERFLOW = Vector2(3, 3)
const TILE_SIZE = Vector2(64, 64)
const HALF_SCREEN = (Vector2(1920, 1080) - TILE_SIZE)/2
const SCREEN_SLIDE_AMOUNT = 400
const SCREEN_SLIDE_SPEED = SCREEN_SLIDE_AMOUNT * 5.0

onready var Grid = find_node("Grid")
onready var Cursor = find_node("Cursor")
onready var CursorMode = find_node("CursorMode")
onready var ComponentMode = find_node("ComponentMode")
onready var TilemapMgr = find_node("TilemapMgr")
onready var Tilemaps = find_node("Tilemaps")

var state = INACTIVE setget set_state
var cursor_pos = Vector2(14, 7) setget set_cursor
var desired_grid_pos = Vector2(0, 0)
var tween:Tween

func set_state(val):
	state = val
	if state == INACTIVE:
		set_process_input(false)
	else:
		set_process_input(true)

func set_cursor(val:Vector2):
	cursor_pos = val
	Cursor.position = cursor_pos*64 - CURSOR_OVERFLOW
	desired_grid_pos = -(Cursor.position - HALF_SCREEN)
	Grid.position = desired_grid_pos


func _ready():
	set_state(INACTIVE)
	set_cursor(Vector2(14, 7))
	if get_tree().root == get_parent():
		enter_levelup()
	load_from_file()
	find_node("Components").visible = false

func load_from_file():
	TilemapMgr.load_from_file("res://levelup/grias_levelup_map.json", Tilemaps, {})

func _input(event):
	if state == CURSOR:
		cursor_input(event)
	elif state == COMPONENT:
		component_input(event)

func cursor_input(event):
	if event.is_action("ui_left") and !event.is_action_released("ui_left"):
		 move_cursor(Vector2.LEFT)
	if event.is_action ("ui_right") and !event.is_action_released("ui_right"):
		 move_cursor(Vector2.RIGHT)
	if event.is_action ("ui_up") and !event.is_action_released("ui_up"):
		 move_cursor(Vector2.UP)
	if event.is_action ("ui_down") and !event.is_action_released("ui_down"):
		 move_cursor(Vector2.DOWN)
	if event.is_action_pressed("ui_accept"):
		enter_component_mode()
	if event.is_action_pressed("ui_cancel"):
		exit_levelup()

func component_input(event):
	if event.is_action_pressed("ui_cancel"):
		exit_component_mode()

func enter_levelup():
	Grid.position = Vector2.ZERO
	ComponentMode.position = Vector2(-SCREEN_SLIDE_AMOUNT, 0)
	CursorMode.position = Vector2.ZERO
	set_cursor(Vector2(14, 7))
	set_state(CURSOR)
	EventBus.emit_signal("disable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().paused = true
	visible = true
	
func exit_levelup():
	if get_tree().root == get_parent():
		return # if this is the only thing running then we're in a temp scene
	set_state(INACTIVE)
	EventBus.emit_signal("enable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_INHERIT
	get_tree().paused = false
	visible = false
	
func enter_component_mode():
	slide_component_mode_to(SCREEN_SLIDE_AMOUNT)
	set_state(INACTIVE)
	yield(tween, "tween_all_completed")
	set_state(COMPONENT)

func exit_component_mode():
	slide_component_mode_to(0)
	set_state(INACTIVE)
	yield(tween, "tween_all_completed")
	set_state(CURSOR)

func move_cursor(dir:Vector2):
	set_cursor(cursor_pos + dir)

func slide_component_mode_to(pos):
	if is_instance_valid(tween):
		tween.stop_all()
		tween.queue_free()
	tween = Util.one_shot_tween(self)
	var cur_pos = CursorMode.position.x
	var move_amt = pos - cur_pos
	var move_time = abs(move_amt) / SCREEN_SLIDE_SPEED
	tween.interpolate_property(CursorMode, "position:x", CursorMode.position.x, CursorMode.position.x+move_amt, move_time)
	tween.interpolate_property(Grid, "position:x", Grid.position.x, Grid.position.x-move_amt/2, move_time)
	tween.interpolate_property(ComponentMode, "position:x", ComponentMode.position.x, ComponentMode.position.x+move_amt*2, move_time)
	tween.start()
