extends Node2D
class_name BoulderBreakGame

enum State {LOADING, MOVING, CHARGING, SMASHING, INACTIVE}

const STRENGTH_SPRITES = [
	preload("res://dungeon/tiles/1.png"),
	preload("res://dungeon/tiles/2.png"),
	preload("res://dungeon/tiles/3.png"),
	preload("res://dungeon/tiles/4.png"),
	preload("res://dungeon/tiles/5.png"),
]

const SMASH_SPRITE = preload("res://img/levelup/node_focus.png")

const TILE_SIZE = 64
const MAX_TOUGHNESS = 4
const POWERUP_SECONDS = 1.73/2

var boulder_gate
var state = State.LOADING
var direction = 1
var grid_size
var ticks_per_move = 5
var seconds_per_move
var tick_counter = 0
var cursor_pos
var swing_progress = 0
var swing_strength = 0
var max_swing_strength = 3
var rand_hash
var first_move = true
var move_progress:float = 0

var BoulderTileGrid:GridContainer
var Cursor:Node2D
var MoveTween:Tween
var StrengthDisplay:TextureRect

func setup(_boulder_gate, _grid_size):
	set_process(false)
	rand_hash = randi()
	boulder_gate = _boulder_gate
	grid_size = _grid_size
	cursor_pos = 0 #randi() % (4*grid_size)
	direction = 1 #randi() % 2
	if direction == 0:
		direction = -1
	BoulderTileGrid = find_node("BoulderTileGrid")
	Cursor = find_node("Cursor")
	MoveTween = find_node("MoveTween")
	StrengthDisplay = find_node("StrengthDisplay")
	seconds_per_move = $Timer.time_left * ticks_per_move
	show_charging_message(true)

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
	update_movement()

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
	elif state == State.CHARGING:
		charging_input(event)

func moving_input(event):
	if event.is_action_pressed("ui_accept"):
		start_smash()
	if event.is_action_pressed("ui_cancel"):
		exit_minigame()

func charging_input(event):
	if event.is_action_released("ui_accept"):
		finish_smash()

func update_movement():
	if state == State.MOVING or state == State.CHARGING:
		tick_counter += 1
		if tick_counter >= ticks_per_move:
			Cursor.visible = true
			tick_counter = 0
			move_cursor_pos(direction)
			var new_position = BoulderTileGrid.get_tile_by_border_index(cursor_pos)
			MoveTween.stop_all()
			if first_move:
				first_move = false
				Cursor.position = new_position.get("pos")
				Cursor.rotation_degrees = new_position.get("rot")
			MoveTween.interpolate_property(Cursor, "position", Cursor.position, new_position.get("pos"), seconds_per_move)
			if Cursor.rotation_degrees > 180 and new_position.get("rot") == 0:
				Cursor.rotation_degrees = -90
			elif Cursor.rotation_degrees < 90 and Cursor.rotation_degrees >= 0 and new_position.get("rot") == 270:
				Cursor.rotation_degrees = 360
			MoveTween.interpolate_property(Cursor, "rotation_degrees", Cursor.rotation_degrees, new_position.get("rot"), seconds_per_move)
			MoveTween.interpolate_property(self, "move_progress", 0, 1.0, seconds_per_move)
			MoveTween.start()
			#Cursor.position = new_position.get("pos")
			#Cursor.rotation_degrees = new_position.get("rot")

func move_cursor_pos(direction):
	cursor_pos = wrapi(cursor_pos + direction, 0, 4*grid_size)

func start_smash():
	set_process(true)
	state = State.CHARGING
	show_charging_message(false)
	swing_strength = 0
	swing_progress = 0

func finish_smash():
	set_process(false)
	if move_progress > 0.5:
		apply_smash(swing_strength, cursor_pos)
		MoveTween.stop_all()
	else:
		cursor_pos = cursor_pos-direction
		apply_smash(swing_strength, cursor_pos)
		MoveTween.stop_all()
	direction = -direction
	state = State.SMASHING
	show_charging_message(true)
	swing_strength = 0
	swing_progress = 0
	update_swing_progress()
	yield(get_tree().create_timer(0.5), "timeout")
	set_process(true)
	state = State.MOVING

func apply_smash(swing_strength, at_position):
	var tile_data = BoulderTileGrid.get_tile_by_border_index(at_position)
	var hit_coords = tile_data["tile_pos"]
	var hit_vec = tile_data["vec"]
	while swing_strength > 0 and hit_coords.x >= 0 and hit_coords.y >= 0 and hit_coords.x < grid_size and hit_coords.y < grid_size:
		var tile_node = BoulderTileGrid.get_tile_node_by_coords(hit_coords)
		if tile_node.toughness > 0:
			var damage = min(tile_node.toughness, swing_strength)
			tile_node.toughness -= damage
			swing_strength -= damage
		hit_coords += hit_vec

func _process(delta):
	if state == State.CHARGING:
		swing_progress += delta / POWERUP_SECONDS
		swing_strength = round((1 - abs(cos(swing_progress))) * max_swing_strength)
	update_swing_progress()

func update_swing_progress():
	if state == State.SMASHING:
		StrengthDisplay.texture = SMASH_SPRITE
	else:
		StrengthDisplay.texture = STRENGTH_SPRITES[floor(swing_strength)]

func show_charging_message(show):
	find_node("StartChargingLabel").visible = show
	find_node("FinishChargingLabel").visible = !show
