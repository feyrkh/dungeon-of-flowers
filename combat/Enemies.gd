extends Node2D

signal target_cancelled()
signal single_enemy_target_complete(target_enemy, move_data)

const TargetMarker = preload("res://combat/TargetMarker.tscn")
const Enemy = preload("res://combat/Enemy.tscn")
						 # 0  1  2  3  4  5  6  7  8  9
const MOVE_OFFSET_LEFT  = [1, 3, 0, 4, 2, 7, 5, 9, 6, 8]
const MOVE_OFFSET_RIGHT = [2, 0, 4, 1, 3, 6, 8, 5, 9, 7]
const MOVE_OFFSET_UP    = [6, 5, 8, 7, 9, 0, 2, 1, 4, 3]
const MOVE_OFFSET_DOWN  = [5, 7, 6, 9, 8, 1, 0, 3, 2, 4]

onready var EnemyImages = find_node("EnemyImages")
onready var TargetIcons = find_node("TargetIcons")

var targeted_enemy_idx
var targeted_ally_idx
var active_target_type
var active_move_data

func _ready():
	for enemy_pos in EnemyImages.get_children():
		var marker = TargetMarker.instance()
		marker.rect_position = enemy_pos.global_position
		marker.rect_rotation = 180
		marker.visible = false
		TargetIcons.add_child(marker)
		enemy_pos.set_target_marker(marker)
	set_process(false)
	CombatMgr.connect("start_enemy_turn", self, "_on_CombatScreen_start_enemy_turn")
	CombatMgr.connect("enemy_turn_complete", self, "_on_CombatScreen_enemy_turn_complete")

func start_targeting(_active_move_data):
	self.active_move_data = _active_move_data
	active_target_type = active_move_data.target
	match active_target_type:
		"enemy": 
			retarget_last_targeted_enemy()
		"all_enemies": printerr(active_target_type+" not implemented yet")
		"random_enemy": printerr(active_target_type+" not implemented yet")
		"ally": printerr(active_target_type+" not implemented yet")
		"all_allies": printerr(active_target_type+" not implemented yet")
		"self": printerr(active_target_type+" not implemented yet")
		_: 
			printerr(active_target_type+" unexpected move target type")
			return
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
	elif Input.is_action_just_pressed("ui_up"):
		target_next_enemy(MOVE_OFFSET_UP)
	elif Input.is_action_just_pressed("ui_down"):
		target_next_enemy(MOVE_OFFSET_DOWN)

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

func add_enemy(enemyData):
	var positionIdx = 0
	while find_node("EnemyPos"+str(positionIdx)).get_child_count() != 0:
		positionIdx += 1
	var enemy = Enemy.instance()
	enemy.setup(enemyData)
	var posNode = find_node("EnemyPos"+str(positionIdx))
	posNode.set_enemy(enemy)
	posNode.add_child(enemy)
	positionIdx += 1

func render_enemies(enemies):
	var enemyNames = {}
	for enemyData in enemies:
		add_enemy(enemyData)
		enemyNames[enemyData.label] = enemyNames.get(enemyData.label, 0) + 1
		
	var enemyNamesList = ""
	var counter = enemyNames.keys().size()
	for enemyName in enemyNames.keys():
		if enemyNames[enemyName] > 1:
			enemyNamesList += str(enemyNames[enemyName]) + " " + enemyName+"s"
		else:
			enemyNamesList += enemyName
		counter -= 1
		if counter == 1:
			enemyNamesList += " and "
		elif counter > 1:
			enemyNamesList += ", "

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

func _on_CombatScreen_start_enemy_turn(combat_data):
	$Bouncer.running = true

func _on_CombatScreen_enemy_turn_complete(combat_data):
	$Bouncer.running = false
