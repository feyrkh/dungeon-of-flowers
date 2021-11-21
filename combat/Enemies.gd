extends Node2D

signal target_cancelled()
signal single_enemy_target_complete(target_enemy, move_data)

const TargetMarker = preload("res://combat/TargetMarker.tscn")
const Enemy = preload("res://combat/Enemy.tscn")
						 # 0  1  2  3  4  5  6  7  8  9
#const MOVE_OFFSET_LEFT  = [1, 3, 0, 4, 2, 7, 5, 9, 6, 8]
#const MOVE_OFFSET_RIGHT = [2, 0, 4, 1, 3, 6, 8, 5, 9, 7]
#const MOVE_OFFSET_UP    = [6, 5, 8, 7, 9, 0, 2, 1, 4, 3]
#const MOVE_OFFSET_DOWN  = [5, 7, 6, 9, 8, 1, 0, 3, 2, 4]
const MOVE_OFFSET_LEFT   = [4, 3, 2, 1, 0]
const MOVE_OFFSET_RIGHT  = [1, 2, 3, 4, 0]

onready var EnemyImages = find_node("EnemyImages")
onready var TargetIcons = find_node("TargetIcons")

var targeted_enemy_idx
var targeted_ally_idx
var active_target_type
var active_move_data
var original_enemy_positions = {}
var squished_enemy_positions = {}

func _ready():
	for enemy_pos in EnemyImages.get_children():
		original_enemy_positions[enemy_pos.name] = enemy_pos.global_position
		squished_enemy_positions[enemy_pos.name] = enemy_pos.global_position - Vector2(enemy_pos.global_position.x/3, 0)
		var marker = TargetMarker.instance()
		marker.rect_position = enemy_pos.global_position
		marker.rect_rotation = 180
		marker.visible = false
		TargetIcons.add_child(marker)
		enemy_pos.set_target_marker(marker)
	set_process(false)
	CombatMgr.connect("start_enemy_turn", self, "_on_CombatScreen_start_enemy_turn")
	CombatMgr.connect("enemy_turn_complete", self, "_on_CombatScreen_enemy_turn_complete")
	owner.connect("allies_win", self, "on_allies_win")
	owner.connect("allies_lose", self, "on_allies_lose")
	

func start_targeting(_active_move_data, cur_ally):
	match _active_move_data.target:
		"enemy": 
			retarget_last_targeted_enemy()
		"all_enemies": printerr(active_target_type+" not implemented yet")
		"random_enemy": printerr(active_target_type+" not implemented yet")
		"ally": return # do nothing, Enemies class doesn't care about ally targeting
		"all_allies": return # do nothing, Enemies class doesn't care about ally targeting
		"self": return # do nothing, Enemies class doesn't care about ally targeting
		_: 
			printerr(active_target_type+" unexpected move target type")
			return
	self.active_move_data = _active_move_data
	active_target_type = active_move_data.target
	set_process(true)

func stop_targeting():
	set_process(false)
	for icon in TargetIcons.get_children():
		icon.visible = false

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		stop_targeting()
		emit_signal("target_cancelled")
	if active_target_type == "enemy":
		process_single_enemy_input()

func process_single_enemy_input():
	if Input.is_action_just_pressed("ui_accept"):
		stop_targeting()
		emit_signal("single_enemy_target_complete", get_enemy(targeted_enemy_idx), active_move_data)
	elif Input.is_action_just_pressed("ui_left"):
		target_next_enemy(MOVE_OFFSET_LEFT)
	elif Input.is_action_just_pressed("ui_right"):
		target_next_enemy(MOVE_OFFSET_RIGHT)
#	elif Input.is_action_just_pressed("ui_up"):
#		target_next_enemy(MOVE_OFFSET_UP)
#	elif Input.is_action_just_pressed("ui_down"):
#		target_next_enemy(MOVE_OFFSET_DOWN)

func target_next_enemy(offset_map):
	var start_idx = targeted_enemy_idx
	var new_idx = offset_map[start_idx]
	var next_enemy_target = null
	while next_enemy_target == null and new_idx != start_idx:
		next_enemy_target = get_enemy(new_idx)
		if next_enemy_target != null:
			target_enemy(new_idx)
			return
		new_idx = offset_map[new_idx]
	print("No enemy targeted, wrapped back around to start")

func get_enemy(enemy_idx):
	if enemy_idx == null: return null
	if EnemyImages.get_child(enemy_idx).get_child_count() != 0:
		var enemy = EnemyImages.get_child(enemy_idx).get_child(0)
		if enemy.is_alive(): return enemy
		else: return null

func get_target_icon(enemy_idx):
	if enemy_idx == null: return null
	return TargetIcons.get_child(enemy_idx)

func retarget_last_targeted_enemy():
	if targeted_enemy_idx == null or get_enemy(targeted_enemy_idx) == null:
		target_first_enemy()
	else:
		target_enemy(targeted_enemy_idx)

func target_first_enemy():
	for i in range(EnemyImages.get_child_count()):
		var enemy = get_enemy(i)
		if enemy != null:
			target_enemy(i)
			return

func target_enemy(enemy_idx):
	var old_target = get_target_icon(targeted_enemy_idx)
	if old_target != null: old_target.visible = false
	targeted_enemy_idx = enemy_idx
	var new_target = get_target_icon(targeted_enemy_idx)
	new_target.visible = true

func add_enemy(enemyData, position_name, spread_factor):
	var enemy = Enemy.instance()
	enemy.setup(enemyData, spread_factor)
	var posNode = find_node(position_name)
	posNode.set_enemy(enemy)
	posNode.add_child(enemy)

func render_enemies(enemies):
	var enemyNames = {}
	var enemy_count = min(3, enemies.size())
	var positions = [["EnemyPos2"], ["EnemyPos1", "EnemyPos3"], ["EnemyPos2", "EnemyPos0", "EnemyPos4"]][enemy_count-1]
	var spread_factor = [2.5, 1.25, -0.1][enemy_count-1]
	for i in range(enemy_count):
		add_enemy(enemies[i], positions[i], spread_factor)

func decide_enemy_actions():
	var enemies = get_live_enemies()
	for enemy in enemies:
		enemy.decide_enemy_action()

func get_live_enemies():
	var enemies = []
	for pos in EnemyImages.get_children():
		if pos.enemy != null and is_instance_valid(pos.enemy) and pos.enemy.is_alive():
			enemies.append(pos.enemy)
	return enemies

func squish_for_minigame(move_time=0.5):
	for enemy_pos in EnemyImages.get_children():
		enemy_pos.set_target_position(squished_enemy_positions[enemy_pos.name], move_time)

func unsquish_for_minigame(move_time=0.5):
	for enemy_pos in EnemyImages.get_children():
		enemy_pos.set_target_position(original_enemy_positions[enemy_pos.name], move_time)

func _on_CombatScreen_start_enemy_turn(combat_data):
	pass
	#$Bouncer.running = true

func _on_CombatScreen_enemy_turn_complete(combat_data):
	pass
	#$Bouncer.running = false

func _on_allies_win(combat_data):
	stop_targeting()

func _on_allies_lose(combat_data):
	stop_targeting()
