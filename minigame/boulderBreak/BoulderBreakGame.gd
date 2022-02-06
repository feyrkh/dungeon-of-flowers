extends Node2D
class_name BoulderBreakGame

enum State {LOADING, MOVING, ROTATING, CHARGING, SMASHING, INACTIVE, WINNING}

const STRENGTH_SPRITES = [
	preload("res://dungeon/tiles/1.png"),
	preload("res://dungeon/tiles/2.png"),
	preload("res://dungeon/tiles/3.png"),
	preload("res://dungeon/tiles/4.png"),
	preload("res://dungeon/tiles/5.png"),
]
const TIRED_SPRITES = [
	preload("res://dungeon/tiles/6.png"),
	preload("res://dungeon/tiles/7.png"),
	preload("res://dungeon/tiles/8.png"),
	preload("res://dungeon/tiles/9.png"),
	preload("res://dungeon/tiles/10.png"),
]

const SMASH_SPRITE = preload("res://img/levelup/node_focus.png")

const TILE_SIZE = 64
const MAX_TOUGHNESS = 4
const POWERUP_SECONDS = 0.73/2
const CURSOR_OFFSET = Vector2(0, -100)
const CURSOR_MOVE_TIME = 2.0

var grid_save_data = null

var boulder_gate
var state = State.LOADING
var direction = 1
var grid_size
var ticks_per_move = 5
var seconds_per_move
var tick_counter = 0
var swing_progress = 0
var swing_strength = 0
var max_swing_strength = 3
var rand_hash
var first_move = true

var bounds_top
var bounds_left
var bounds_bottom
var bounds_right
var cursor_x = 0
var cursor_y = 0
var cursor_vec = Vector2.DOWN
var grid_top_left:Vector2

var GriasDisplay
var BoulderTileGrid:GridContainer
var Cursor:Node2D
var MoveTween:Tween
var StrengthDisplay:TextureRect

func setup(_boulder_gate, _grid_size):
	set_process(false)
	rand_hash = randi()
	boulder_gate = _boulder_gate
	grid_size = _grid_size
	bounds_left = 0
	bounds_top = 0
	bounds_bottom = grid_size-1
	bounds_right = grid_size-1
	direction = 1 #randi() % 2
	if direction == 0:
		direction = -1
	BoulderTileGrid = find_node("BoulderTileGrid")
	Cursor = find_node("Cursor")
	MoveTween = find_node("MoveTween")
	StrengthDisplay = find_node("StrengthDisplay")
	GriasDisplay = find_node("GriasDisplay")
	seconds_per_move = $Timer.time_left * ticks_per_move
	show_charging_message(true)

func _ready() -> void:
	if get_tree().root == self.get_parent():
		var mock_boulder = load("res://dungeon/tiles/GateBoulder.tscn").instance()
		mock_boulder.map_config = {}
		setup(mock_boulder, 9)
		GameData.setup_allies()
	GriasDisplay.setup(GameData.allies[1])
	#$Timer.connect("timeout", self, "update_movement")
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
		"grid_save_data": BoulderTileGrid.save_data()
	}
	boulder_gate.minigame_config = save_data

func restore_minigame():
	Util.config(self, boulder_gate.minigame_config)

func enter_minigame():
	set_state(State.LOADING)
	restore_minigame()
	EventBus.emit_signal("disable_pause_menu")
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().paused = true
	visible = true
	if grid_save_data == null:
		BoulderTileGrid.generate_grid(boulder_gate.map_position, grid_size, MAX_TOUGHNESS)
	else:
		BoulderTileGrid.restore_data(grid_save_data)
	Cursor.visible = false
	yield(get_tree(), "idle_frame")
	grid_top_left = BoulderTileGrid.get_global_rect().position
	Cursor.visible = true
	MoveTween.interpolate_property(Cursor, "position", CURSOR_OFFSET + grid_top_left, CURSOR_OFFSET + grid_top_left + Vector2(BoulderTileGrid.get_global_rect().size.x, 0), CURSOR_MOVE_TIME)
	MoveTween.interpolate_property(Cursor, "position", CURSOR_OFFSET + grid_top_left + Vector2(BoulderTileGrid.get_global_rect().size.x, 0), CURSOR_OFFSET + grid_top_left, CURSOR_MOVE_TIME, Tween.TRANS_LINEAR, 0, CURSOR_MOVE_TIME)
	MoveTween.start()
	set_state(State.MOVING)
	#update_movement()

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
	if Input.is_action_pressed("debug_skip_combat"):
		boulder_gate.open()
		exit_minigame()
	if state == State.MOVING:
		moving_input(event)
	elif state == State.CHARGING:
		charging_input(event)

func moving_input(event):
	if event.is_action_pressed("ui_accept"):
		start_smash()
	elif event.is_action_pressed("ui_cancel"):
		exit_minigame()
	elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("rotate_left"):
		rotate_grid(-1)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("rotate_right"):
		rotate_grid(1)

func rotate_grid(dir):
	BoulderTileGrid.rotate_grid(dir)
	state = State.ROTATING
	yield(BoulderTileGrid, "rotation_complete")
	state = State.MOVING

func charging_input(event):
	if event.is_action_released("ui_accept"):
		finish_smash()

func start_smash():
	set_process(true)
	state = State.CHARGING
	show_charging_message(false)
	swing_strength = 0
	swing_progress = 0

func finish_smash():
	set_process(false)
	GameData.set_sp_damage_label(["stone", "smash", "slam", "slab", "slice", "swing", "stamina", "stonemason", "stability"])
	apply_smash()
	MoveTween.stop_all()
	direction = -direction
	state = State.SMASHING
	show_charging_message(true)
	swing_strength = 0
	swing_progress = 0
	update_swing_progress()
	yield(get_tree().create_timer(0.5), "timeout")
	if !BoulderTileGrid.is_game_complete():
		set_process(true)
		MoveTween.resume_all()
		state = State.MOVING
	else:
		state = State.WINNING
		yield(get_tree().create_timer(1), "timeout")
		boulder_gate.open()
		exit_minigame()

func apply_smash():
	var border_index = floor((Cursor.position.x -  grid_top_left.x) / TILE_SIZE)
	border_index += BoulderTileGrid.down_vector_idx * grid_size
	var tile_data = BoulderTileGrid.get_tile_by_border_index(border_index)
	var hit_coords = tile_data["tile_pos"]
	var hit_vec = tile_data["vec"]
	var delay = 0
	if GriasDisplay.data.sp.value > 0:
		swing_strength *= 2
	GriasDisplay.data.sp.value -= 1
	while swing_strength > 0 and hit_coords.x >= 0 and hit_coords.y >= 0 and hit_coords.x < grid_size and hit_coords.y < grid_size:
		var tile_node = BoulderTileGrid.get_tile_node_by_coords(hit_coords)
		if tile_node.toughness > 0:
			var damage = min(tile_node.toughness, swing_strength)
			tile_node.toughness -= damage
			swing_strength -= damage
		hit_coords += hit_vec
		BoulderTileGrid.destroy_small_chunks()

func _process(delta):
	if state == State.MOVING:
		pass
	elif state == State.CHARGING:
		swing_progress += delta / POWERUP_SECONDS
		swing_strength = round((1 - abs(cos(swing_progress))) * max_swing_strength)
	update_swing_progress()

func update_swing_progress():
	if state == State.SMASHING:
		StrengthDisplay.texture = SMASH_SPRITE
	else:
		if GriasDisplay.data.sp.value > 0:
			StrengthDisplay.texture = STRENGTH_SPRITES[floor(swing_strength)]
		else:
			StrengthDisplay.texture = TIRED_SPRITES[floor(swing_strength)]

func show_charging_message(show):
	find_node("StartChargingLabel").visible = show
	find_node("FinishChargingLabel").visible = !show
