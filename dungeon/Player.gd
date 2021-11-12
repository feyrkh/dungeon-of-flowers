extends Spatial

signal move_complete
signal turn_complete
signal tile_move_complete

const ROTATE_TIME = 0.5
const MOVE_TIME = 0.5
const TILE_METADATA_MASK = 2
const EMPTY_ARRAY = []
const UP_VECTOR = Vector3(0, 1, 0)

var is_moving = false
var start_rotation
var target_rotation
var start_position
var target_position
var rotation_time
var move_time
var move_multiplier = 1.0
var is_bumping = false
var is_in_combat = false
var interactable = []

onready var forwardSensor:Area = find_node("forwardSensor")
onready var backwardSensor:Area = find_node("backwardSensor")
onready var leftSensor:Area = find_node("leftSensor")
onready var rightSensor:Area = find_node("rightSensor")

const wall_bump_sfx = preload("res://sound/thump.mp3")
const walk_sfx = preload("res://sound/footsteps.wav")


func _ready():
	EventBus.connect("pre_new_game", self, "on_pre_new_game")
	EventBus.connect("finalize_new_game", self, "on_finalize_new_game")
	EventBus.connect("post_load_game", self, "on_post_load_game")
	EventBus.connect("finalize_load_game", self, "on_finalize_load_game")
	EventBus.connect("player_start_move", self, "_on_move_start")
	EventBus.connect("player_start_turn", self, "_on_move_start")
	EventBus.connect("refresh_interactables", self, "find_interactables")
	connect("move_complete", self, "_on_move_complete")
	connect("turn_complete", self, "_on_turn_complete")
	connect("tile_move_complete", QuestMgr, "on_tile_move_complete")

func on_pre_new_game():
	transform = transform.looking_at(transform.origin + Vector3(0, 0, 1), Vector3.UP)

func on_finalize_new_game():
	call_deferred("update_minimap")
	EventBus.emit_signal("new_player_location", global_transform.origin.x/3, global_transform.origin.z/3, rad2deg(global_transform.basis.get_euler().y))


func on_post_load_game():
	pass
	
func on_finalize_load_game():
	pass

func _on_combat_start():
	is_in_combat = true

func _on_combat_end():
	is_in_combat = false

func process_input():
	if is_in_combat:
		return
	if Input.is_action_just_pressed("ui_accept"):
		interact()
	if is_moving or is_bumping: 
		return
	if Input.is_action_pressed("move_forward"):
		if can_move(forwardSensor):
			move(1)
		else:
			bump_forward(1)
	elif Input.is_action_pressed("move_backward"):
		if can_move(backwardSensor):
			move(-1)
		else:
			bump_forward(-1)
	if Input.is_action_pressed("move_left"):
		if can_move(leftSensor):
			sidestep(1)
		else:
			bump_sideways(1)
	elif Input.is_action_pressed("move_right"):
		if can_move(rightSensor):
			sidestep(-1)
		else:
			bump_sideways(-1)
	elif Input.is_action_pressed("turn_left"):
		turn(-1)
	elif Input.is_action_pressed("turn_right"):
		turn(1)

func bump_forward(dir):
	is_bumping = true
	move_multiplier = 4
	move(0.1*dir)
	yield(self, "move_complete")
	var pitch_scale = randf()*0.3 + 0.85
	AudioPlayerPool.play(wall_bump_sfx, pitch_scale)
	move(-0.1*dir)
	yield(self, "move_complete")
	move_multiplier = 1
	is_bumping = false

func bump_sideways(dir):
	is_bumping = true
	move_multiplier = 4
	sidestep(0.1*dir)
	yield(self, "move_complete")
	var pitch_scale = randf()*0.3 + 0.85
	AudioPlayerPool.play(wall_bump_sfx, pitch_scale)
	sidestep(-0.1*dir)
	yield(self, "move_complete")
	move_multiplier = 1
	is_bumping = false

func can_move(sensor):
	var areas = sensor.get_overlapping_areas()
	if areas.size() == 0:
		print("Can't move, no open space ahead")
		return false
	else:
		print(areas.size(), " areas overlapping")
		for area in areas:
			print(area.name)
			var tile_metadata:TileMetadata = area.owner.find_node("TileMetadata", true, false)
			if tile_metadata:
				return tile_metadata.can_move_onto
		return false

func _on_move_start():
	interactable = []
	update_interactable_prompt()

func _on_move_complete():
	target_position = null
	move_time = 0
	is_moving = false
	find_interactables(get_facing_tile_coords((global_transform.origin/3).round(), global_transform.basis.z, 1))

func _on_turn_complete():
	target_rotation = null
	rotation_time = 0
	is_moving = false
	find_interactables(get_facing_tile_coords((global_transform.origin/3).round(), global_transform.basis.z, 1))

func get_tile_coords():
	return Vector2(round(global_transform.origin.x/3), round(global_transform.origin.z/3))

func get_facing_tile_coords(standing_point, facing, distance=1):
	var facing_coords = standing_point - facing * distance
	facing_coords = Vector2(round(facing_coords.x), round(facing_coords.z))
	return facing_coords

func find_interactables(coords=null):
	if coords == null:
		coords = get_facing_tile_coords((global_transform.origin/3).round(), global_transform.basis.z, 1)
	interactable = []
	var scenes_on_facing_tile = GameData.dungeon.get_all_tile_scenes(coords)
	for scene in scenes_on_facing_tile:
		if scene and scene.has_method("is_interactable") and scene.is_interactable():
			interactable.append(scene)
	update_interactable_prompt()

func update_interactable_prompt():
	EventBus.emit_signal("update_interactable", interactable)

func interact():
	if !interactable or !interactable.size():
		return
	if interactable[0].is_interactable():
		interactable[0].interact()

func _process(delta):
	process_input()
	if target_position:
		move_time += delta*move_multiplier
		if move_time < MOVE_TIME:
			global_transform.origin = (target_position - start_position)*(move_time/MOVE_TIME)+start_position
		else:
			global_transform.origin = target_position
			emit_signal("move_complete")
			EventBus.emit_signal("player_finish_move")
			#print("ended move at ", OS.get_system_time_msecs())
			if !is_bumping:
				emit_signal("tile_move_complete")
				#EventBus.emit_signal("new_player_location", global_transform.origin.x/3, global_transform.origin.z/3, rad2deg(global_transform.basis.get_euler().y))
				update_minimap()
	if target_rotation != null:
		rotation_time += delta
		if rotation_time < ROTATE_TIME:
			transform.basis = start_rotation.slerp(target_rotation, rotation_time/ROTATE_TIME)
		else:
			transform.basis = target_rotation
			emit_signal("turn_complete")
			EventBus.emit_signal("player_finish_turn")
			#EventBus.emit_signal("new_player_location", global_transform.origin.x/3, global_transform.origin.z/3, rad2deg(global_transform.basis.get_euler().y))
			update_minimap()

func update_minimap():
	var tile_x = round(global_transform.origin.x/3)
	var tile_z = round(global_transform.origin.z/3)
	for z in range(tile_z-1, tile_z+2):
		for x in range(tile_x-1, tile_x+2):
			var tile_type = query_tile_metadata(x, z)
			EventBus.emit_signal("uncovered_map_tile", x, z, tile_type)
	EventBus.emit_signal("update_minimap")

func query_tile_metadata(tile_x, tile_z):
	var space_state = get_world().direct_space_state
	var pos = Vector3(tile_x*3, 0, tile_z*3)
	var result = space_state.intersect_ray(pos, pos+UP_VECTOR, EMPTY_ARRAY, TILE_METADATA_MASK, false, true)
	#print("Found tile metadata: ", result)
	if result.has("collider"):
		return result.get("collider").tile_name
	return "empty"

func move(dir):
	if is_moving: 
		return
	is_moving = true
	if !is_bumping:
		AudioPlayerPool.play(walk_sfx)
	#print("start move at ", OS.get_system_time_msecs())
	start_position = global_transform.origin
	target_position = global_transform.origin + global_transform.basis.z*3 * -dir
	EventBus.emit_signal("new_player_location", round(target_position.x/3), round(target_position.z/3), rad2deg(global_transform.basis.get_euler().y))
	move_time = 0
	EventBus.emit_signal("player_start_move")
	find_interactables(get_facing_tile_coords((target_position/3).round(), global_transform.basis.z, 1))

func sidestep(dir):
	if is_moving:
		return
	is_moving = true
	if !is_bumping:
		AudioPlayerPool.play(walk_sfx)
	#print("start sidestep at ", OS.get_system_time_msecs())
	start_position = global_transform.origin
	target_position = global_transform.origin + global_transform.basis.x*3*-dir
	EventBus.emit_signal("new_player_location", round(target_position.x/3), round(target_position.z/3), rad2deg(global_transform.basis.get_euler().y))
	move_time = 0
	EventBus.emit_signal("player_start_move")
	find_interactables(get_facing_tile_coords((target_position/3).round(), global_transform.basis.z, 1))

func turn(dir):
	if is_moving: 
		return
	is_moving = true
	#print("start rotate at ", OS.get_system_time_msecs())
	start_rotation = transform.basis
	target_rotation = transform.basis.rotated(Vector3.DOWN, deg2rad(90*dir))
	EventBus.emit_signal("new_player_location", round(global_transform.origin.x/3), round(global_transform.origin.z/3), rad2deg(target_rotation.get_euler().y))
	rotation_time = 0
	EventBus.emit_signal("player_start_turn")
	find_interactables(get_facing_tile_coords((global_transform.origin/3).round(), target_rotation.z, 1))

