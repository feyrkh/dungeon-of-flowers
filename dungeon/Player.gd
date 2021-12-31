extends Spatial

signal move_complete
signal turn_complete
signal tile_move_complete

const ROTATE_TIME = 0.5
const MOVE_TIME = 0.5
const TILE_METADATA_MASK = 2
const EMPTY_ARRAY = []
const UP_VECTOR = Vector3(0, 1, 0)
const BUMP_DISTANCE = 0.3
const BUMP_HALF_TIME = 0.125

var is_moving = false
var is_knockback = 0
var start_rotation
var target_rotation
var start_position
var target_position
var rotation_time
var move_time
var move_multiplier = 1.0
var is_bumping = false setget set_is_bumping
var is_in_combat = false
var is_in_cutscene = false
var interactable = []
var bump_tween:Tween
var trap_damage_immunity = 0

func set_is_bumping(val):
	is_bumping = val

onready var forwardSensor:Area = find_node("forwardSensor")
onready var backwardSensor:Area = find_node("backwardSensor")
onready var leftSensor:Area = find_node("leftSensor")
onready var rightSensor:Area = find_node("rightSensor")
onready var knockbackSensor:Area = find_node("knockbackSensor")

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
	QuestMgr.connect("cutscene_start", self, "cutscene_start")
	QuestMgr.connect("cutscene_end", self, "cutscene_end", [], CONNECT_DEFERRED)
	connect("move_complete", self, "_on_move_complete")
	connect("turn_complete", self, "_on_turn_complete")
	connect("tile_move_complete", QuestMgr, "on_tile_move_complete")
	connect("tile_move_complete", ChatMgr, "on_tile_move_complete")
	GameData.player = self

func on_pre_new_game():
	transform = transform.looking_at(transform.origin + Vector3(0, 0, 1), Vector3.UP)

func on_finalize_new_game():
	call_deferred("update_minimap")
	EventBus.emit_signal("new_player_location", global_transform.origin.x/3, global_transform.origin.z/3, rad2deg(global_transform.basis.get_euler().y))
	find_interactables()

func on_post_load_game():
	pass

func on_finalize_load_game():
	find_interactables()
	EventBus.emit_signal("new_player_location", global_transform.origin.x/3, global_transform.origin.z/3, rad2deg(global_transform.basis.get_euler().y))

func _on_combat_start():
	is_in_combat = true

func _on_combat_end():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	is_in_combat = false

func cutscene_start(cutscene_name):
	is_in_cutscene = true

func cutscene_end(cutscene_name):
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	is_in_cutscene = false

func process_input():
	if is_in_combat:
		return
	if is_in_cutscene:
		return
	if is_knockback > 0:
		return
	if Input.is_action_just_pressed("ui_accept"):
		interact()
	if is_moving or is_bumping:
		return
	if Input.is_action_pressed("move_forward"):
		#print("Moving forward: is_moving=", is_moving, "; is_bumping=", is_bumping)
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
	set_is_bumping(true)
	var tween:Tween = Util.one_shot_tween(self)
	var move_vec = Vector3.FORWARD.rotated(Vector3.UP, self.global_transform.basis.get_euler().y) * BUMP_DISTANCE * dir
	tween.interpolate_property(self, "translation", self.translation, self.translation + move_vec, BUMP_HALF_TIME)
	tween.interpolate_property(self, "translation", self.translation + move_vec, self.translation, BUMP_HALF_TIME, 0, 2, BUMP_HALF_TIME)
	Util.delay_call(BUMP_HALF_TIME, self, "make_bump_noise")
	Util.delay_call(BUMP_HALF_TIME*2+0.01, self, "set_is_bumping", [false])
	tween.start()

func make_bump_noise():
	var pitch_scale = randf()*0.3 + 0.85
	AudioPlayerPool.play(wall_bump_sfx, pitch_scale)

func bump_sideways(dir):
	set_is_bumping(true)
	bump_tween = Util.one_shot_tween(self)
	var move_vec = Vector3.LEFT.rotated(Vector3.UP, self.global_transform.basis.get_euler().y) * BUMP_DISTANCE * dir
	bump_tween.interpolate_property(self, "translation", self.translation, self.translation + move_vec, BUMP_HALF_TIME)
	bump_tween.interpolate_property(self, "translation", self.translation + move_vec, self.translation, BUMP_HALF_TIME, 0, 2, BUMP_HALF_TIME)
	Util.delay_call(BUMP_HALF_TIME, self, "make_bump_noise")
	Util.delay_call(BUMP_HALF_TIME*2+0.01, self, "set_is_bumping", [false])
	bump_tween.start()

func can_move(sensor:Area):
	var tile_scene = GameData.dungeon.get_tile_scene("ground", Util.map_coords(sensor.global_transform.origin))
	if !tile_scene:
		return false
	var tile_metadata:TileMetadata = tile_scene.find_node("TileMetadata", true, false)
	if !tile_metadata:
		return false
	return tile_metadata.can_move_onto

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
	if is_knockback > 0:
		is_knockback = max(0, is_knockback-delta)
		if is_knockback > 0:
			center_in_tile()
			global_transform.origin.x = round(global_transform.origin.x) + 0.1 - fmod(randf(), 0.2)
			global_transform.origin.z = round(global_transform.origin.z) + 0.1 - fmod(randf(), 0.2)
		else:
			center_in_tile()
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
				EventBus.emit_signal("tile_entered", Vector2(round(global_transform.origin.x/3), round(global_transform.origin.z/3)), self)
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
			$PerspectiveSpriteUpdateTimer.stop()
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

func move(dir, ignore_bumping=false):
	if is_moving or (!ignore_bumping and is_bumping):
		return
	move_multiplier = 1
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

func sidestep(dir, ignore_bumping=false):
	if is_moving or (!ignore_bumping and is_bumping):
		return
	move_multiplier = 1
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

func knockback(global_dir):
	is_knockback = 0.5
	set_process(true)
	if is_bumping:
		center_in_tile()
	if is_moving and global_dir == null or global_dir == Vector3.ZERO:
		target_position = start_position
		start_position = global_transform.origin
		move_time = 0
		move_multiplier = 4.0
	elif global_dir != null and global_dir != Vector3.ZERO:
		var cur_tile_pos = (global_transform.origin/3).round() * 3
		var tiles_to_move = round(global_dir.length()/3)
		var final_pos = cur_tile_pos
		var tiles_moved = 0
		global_dir = global_dir.normalized()*3
		knockbackSensor.global_transform.origin = cur_tile_pos
		for i in range(tiles_to_move):
			knockbackSensor.global_transform.origin -= global_dir
			knockbackSensor.force_update_transform()
			print("Checking knockback from ", cur_tile_pos, " to ", knockbackSensor.global_transform.origin)
			if can_move(knockbackSensor):
				tiles_moved += 1
				final_pos = knockbackSensor.global_transform.origin
				print("knockback ok")
			else:
				print("knockback not ok")
				break
		if global_transform.origin != final_pos:
			start_position = global_transform.origin
			target_position = final_pos
			move_time = 0
			if tiles_moved > 0:
				move_multiplier = 4.0/tiles_moved

func center_in_tile():
	if is_instance_valid(bump_tween):
		bump_tween.stop_all()
	global_transform.origin = (global_transform.origin/3).round()*3

func turn(dir):
	if is_moving or is_bumping:
		return
	is_moving = true
	target_position = null
	start_position = null
	move_multiplier = 1
	#print("start rotate at ", OS.get_system_time_msecs())
	start_rotation = transform.basis
	target_rotation = transform.basis.rotated(Vector3.DOWN, deg2rad(90*dir))
	EventBus.emit_signal("new_player_location", round(global_transform.origin.x/3), round(global_transform.origin.z/3), rad2deg(target_rotation.get_euler().y))
	rotation_time = 0
	EventBus.emit_signal("player_start_turn")
	$PerspectiveSpriteUpdateTimer.start()
	find_interactables(get_facing_tile_coords((global_transform.origin/3).round(), target_rotation.z, 1))

func _on_PerspectiveSpriteUpdateTimer_timeout():
	EventBus.emit_signal("refresh_perspective_sprites", -global_transform.basis.z)

func trap_hit(trap, knockback_amt):
	if OS.get_system_time_msecs() < trap_damage_immunity:
		return
	trap_damage_immunity = OS.get_system_time_msecs() + 1000
	print("Hit by a trap for ", trap.damage)
	knockback(knockback_amt)
	EventBus.emit_signal("damage_all_allies", trap.damage)
