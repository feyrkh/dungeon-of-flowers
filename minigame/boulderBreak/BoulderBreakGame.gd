extends Node2D
class_name BoulderBreakGame

enum State {LOADING, MOVING, SMASHING, INACTIVE}

const TILE_SIZE = 64
const MAX_TOUGHNESS = 4

var boulder_gate
var state = State.LOADING
var direction = 1
var grid_size
var ticks_per_move = 5
var tick_counter = 0
var cursor_pos
var swing_strength = 0
var max_swing_strength = 3
var rand_hash

var BoulderTileGrid:GridContainer
var Cursor:Node2D

func setup(_boulder_gate, _grid_size):
	rand_hash = randi()
	boulder_gate = _boulder_gate
	grid_size = _grid_size
	cursor_pos = 0 #randi() % (4*grid_size)
	direction = 1 #randi() % 2
	if direction == 0:
		direction = -1
	BoulderTileGrid = find_node("BoulderTileGrid")
	Cursor = find_node("Cursor")

func _ready() -> void:
	if get_tree().root == self.get_parent():
		var mock_boulder = load("res://dungeon/tiles/GateBoulder.tscn").instance()
		mock_boulder.map_config = {}
		setup(mock_boulder, 9)
	$Timer.connect("timeout", self, "update_movement")
	enter_minigame()

func set_state(val):
	state = val
	if state != State.MOVING:
		set_process_input(false)
	else:
		set_process_input(true)

func save_minigame():
	var save_data = {
		"grid_size": grid_size,
		"ticks_per_move": ticks_per_move,
		"rand_hash": rand_hash,
	}
	boulder_gate.map_config["minigame"] = save_data

func restore_minigame():
	Util.config(self, boulder_gate.map_config.get("minigame", {}))

func enter_minigame():
	restore_minigame()
	set_state(State.LOADING)
	EventBus.emit_signal("disable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().paused = true
	visible = true
	BoulderTileGrid.generate_grid(boulder_gate.map_position, grid_size, MAX_TOUGHNESS)
	set_state(State.MOVING)

func exit_minigame():
	if get_tree().root == get_parent():
		return # if this is the only thing running then we're in a temp scene
	save_minigame()
	set_state(State.INACTIVE)
	EventBus.emit_signal("enable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_INHERIT
	get_tree().paused = false
	visible = false
	queue_free()

func _input(event):
	if state == State.MOVING:
		moving_input(event)

func moving_input(event):
	if event.is_action_pressed("ui_accept"):
		start_smash()
	if event.is_action_pressed("ui_cancel"):
		exit_minigame()

func update_movement():
	if state == State.MOVING:
		tick_counter += 1
		if tick_counter >= ticks_per_move:
			tick_counter = 0
			cursor_pos = wrapi(cursor_pos + direction, 0, 4*grid_size)
			var new_position = BoulderTileGrid.get_tile_by_border_index(cursor_pos)
			Cursor.position = new_position.get("pos")
			Cursor.rotation_degrees = new_position.get("rot")

func start_smash():
	direction = -direction
