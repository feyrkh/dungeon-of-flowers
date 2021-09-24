extends Node2D

const SkillButton = preload("res://combat/SkillButton.tscn")
const STATUS_CATEGORY = 4

var combat_data : CombatData

signal start_combat(combat_data)
signal start_player_turn(combat_data)
signal start_enemy_turn(combat_data)
signal player_move_selected(combat_data, target_enemy, move_data)
signal player_move_complete(combat_data)
signal player_turn_complete(combat_data)
signal enemy_move_selected(combat_data, move_data)
signal enemy_move_complete(combat_data, move_data)
signal enemy_turn_complete(combat_data)
signal log_msg(msg)
signal allies_win(combat_data)
signal allies_lose(combat_data)

enum InputPhase {
	PLAYER_SELECT_CHARACTER, PLAYER_SELECT_CATEGORY, PLAYER_SELECT_SUBMENU, PLAYER_SELECT_TARGET, NO_INPUT
}
var cur_input_phase = InputPhase.NO_INPUT
var input_delayed = 0

# Combat flow:
# start_combat() - display any combat opening effects, call start_player_turn or start_enemy_turn depending on surprise
# start_player_turn() - renders player control panel, waits for player to make a selection
# player_move_selected() - hide player control panel, show move results, await player_move_complete
# player_move_complete() - if enemies are dead, combat_complete(); otherwise start_enemy_turn()
# start_enemy_turn() - collect moves from each enemy, call enemy_move_selected() for the first one;
#					   await enemy_move_complete(); 
#					   if more unfinished moves, call enemy_move_selected() for the next
#					   otherwise call enemy_turn_complete()
# enemy_turn_complete() - if enemies are dead, combat_complete; otherwise start_player_turn()

onready var Enemies = find_node("Enemies")
onready var MinigameContainer = find_node("MinigameContainer")
onready var allies = [find_node("Ally1"), find_node("Ally2"), find_node("Ally3")]

var selected_ally_idx = 0
var selected_category_idx = 0
var restore_category_idx = 0 # set when moving to the 'status' icon, so we can restore back to the previously selected item
var selected_skill
var accumulated_damage = 0
var expected_damage = 0
var active_submenu

const UI_DELAY = 0.12

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if (!combat_data):
		combat_data = mock_combat_data()
	render_allies()
	render_enemies()
	#adjustStanceButton.visible = true
	#balanceContainer.visible = false
	input_delayed = UI_DELAY
	emit_signal('start_combat', combat_data)

func _process(delta):
	if input_delayed > 0:
		input_delayed -= delta
	if input_delayed <= 0:
		process_input()

func process_input():
	match(cur_input_phase):
		InputPhase.NO_INPUT: 
			return
		InputPhase.PLAYER_SELECT_CHARACTER:
			input_select_character()
		InputPhase.PLAYER_SELECT_TARGET:
			input_select_target()

func input_select_character():
	if Input.is_action_just_pressed("select_prev_char"):
		select_next_char(-1)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("select_next_char"):
		select_next_char(1)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_up"):
		open_category_submenu(selected_ally_idx, selected_category_idx)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("ui_left"):
		select_next_category(-1)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("ui_right"):
		select_next_category(1)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("ui_down"):
		select_status_category()
		input_delayed = UI_DELAY

func select_next_char(direction):
	var prev_selected = allies[selected_ally_idx]
	var new_selected_ally = null
	for i in range(1, 3):
		var new_selected_ally_idx = (selected_ally_idx + direction*i) % allies.size()
		if new_selected_ally_idx < 0: new_selected_ally_idx += allies.size()
		var next_selected = allies[new_selected_ally_idx]
		if !next_selected.exhausted:
			prev_selected.deselect()
			next_selected.select(selected_category_idx)
			selected_ally_idx = new_selected_ally_idx
			return


func open_category_submenu(ally_idx, category_idx):
	if (category_idx == STATUS_CATEGORY): # status icon, up should go back to previously selected icon instead
		selected_category_idx = restore_category_idx
		select_next_category(0)
	else:
		cur_input_phase = InputPhase.PLAYER_SELECT_SUBMENU
		var ally = allies[ally_idx]
		ally.open_category_submenu(category_idx)

func _on_Ally_cancel_submenu():
	cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
	
func select_next_category(direction):
	var cur_ally = allies[selected_ally_idx]
	selected_category_idx = cur_ally.select_category(selected_category_idx, direction)

func select_status_category():
	if selected_category_idx != STATUS_CATEGORY:
		var cur_ally = allies[selected_ally_idx]
		restore_category_idx = selected_category_idx
		selected_category_idx = cur_ally.select_status_category()
	
func input_select_target():
	pass

func render_allies():
	var allyIdx = 0
	for allyData in combat_data.allies:
		allies[allyIdx].setup(allyData)
		allyIdx += 1

func render_enemies():
	Enemies.render_enemies(combat_data.get_enemies())

func enemies_all_dead():
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.data.hp > 0:
			return false
	return true

func allies_all_dead():
	return combat_data.get_current_ally().hp <= 0

func mock_combat_data():
	var cd = CombatData.new()
	cd.allies = [mock_pharoah(), mock_vega(), mock_shantae()]
	cd.enemies = []
	for i in randi()%2+1:
		cd.enemies.append(EnemyList.get_enemy('random'))
	return cd

func mock_pharoah():
	var ally = AllyData.new()
	ally.label = "Imhotep"
	ally.className = "Pharoah"
	ally.max_hp = 100
	ally.hp = 80
	ally.sp = 20
	ally.max_sp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero1.png")
	ally.moves = [
		MoveList.get_move('kick'),
		MoveList.get_move('headbutt'),
		
	]
	return ally
	
func mock_hipster():
	var ally = AllyData.new()
	ally.label = "Allie"
	ally.className = "Barista"
	ally.max_hp = 100
	ally.hp = 80
	ally.sp = 20
	ally.max_sp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero2.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('headbutt'),
	]
	return ally
	
func mock_shantae():
	var ally = AllyData.new()
	ally.label = "Shantae"
	ally.className = "Half Genie"
	ally.max_hp = 100
	ally.hp = 80
	ally.sp = 20
	ally.max_sp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero3.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('kick')
	]
	return ally
	
func mock_vega():
	var ally = AllyData.new()
	ally.label = "Vega"
	ally.className = "Street Fighter"
	ally.max_hp = 100
	ally.hp = 80
	ally.sp = 20
	ally.max_sp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero4.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('kick'),
		MoveList.get_move('headbutt'),
	]
	return ally

func _on_CombatScreen_start_combat(_combat_data):
	# todo: surprise attacks, screen effects
	#playerInput.visible = false
	#playerSprite.visible = false
	yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("start_player_turn", _combat_data)


func _on_CombatScreen_start_player_turn(_combat_data):
	emit_signal("log_msg", "It's "+_combat_data.get_current_ally().label+"'s turn!")
	cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
	selected_ally_idx = 0
	allies[selected_ally_idx].select(selected_category_idx)
	#playerInput.visible = true
	#playerSprite.visible = true
	selected_skill = null
	#playerSprite.find_node("PlayerPulser").start()
	#render_ally_moves(_combat_data)
	#highlight_targeted_enemy()
	#enable_enemy_targeting()

func _on_CombatScreen_player_move_complete(_combat_data):
	print("_on_CombatScreen_player_move_complete")
	#unhighlight_targeted_enemy()
	#disable_enemy_targeting()
	if check_combat_over():
		return
	if check_player_turn_over():
		emit_signal("player_turn_complete", _combat_data)
		emit_signal("start_enemy_turn", _combat_data)
	else:
		cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
		select_next_char(1)

func check_player_turn_over():
	print("check_player_turn_over")
	for ally in allies:
		if ally != null and !ally.exhausted:
			return false
	return true

func _on_CombatScreen_start_enemy_turn(_combat_data):
	print("log_msg", "The enemy is confused...")
	yield(get_tree().create_timer(2), "timeout")
	print("log_msg", "The enemy just stands there!")
	emit_signal("enemy_turn_complete", _combat_data)

func _on_CombatScreen_enemy_turn_complete(_combat_data):
	yield(get_tree().create_timer(0.5), "timeout")
	if check_combat_over():
		return
	emit_signal("start_player_turn", _combat_data)

func check_combat_over():
	print("check_combat_over")
	if enemies_all_dead():
		emit_signal("allies_win", combat_data)
		return true
	elif allies_all_dead():
		emit_signal("allies_lose", combat_data)
		return true
	return false

func _on_Ally_select_submenu_item(submenu, move_data):
	active_submenu = submenu
	cur_input_phase = InputPhase.PLAYER_SELECT_TARGET
	allies[selected_ally_idx].on_targeting_started(move_data)
	Enemies.start_targeting(move_data)

func _on_Enemies_target_cancelled():
	active_submenu.on_targeting_cancelled()
	allies[selected_ally_idx].on_targeting_cancelled()
	
func _on_Enemies_single_enemy_target_complete(target_enemy, move_data):
	active_submenu.on_targeting_completed()
	allies[selected_ally_idx].on_targeting_completed()
	emit_signal("player_move_selected", combat_data, target_enemy, move_data)

func _on_CombatScreen_player_move_selected(_combat_data, target_enemy, move_data):
	print("Attacking ", target_enemy.name, " with skill: ", move_data.label)
	var scene = move_data.get_attack_scene(target_enemy)
	MinigameContainer.add_child(scene)
	MinigameContainer.visible = true
	scene.connect("minigame_success", target_enemy, "damage_hp")
	scene.position = (MinigameContainer.rect_size/2)
	yield(get_tree().create_timer(0.5), "timeout")
	scene.connect("minigame_complete", self, "_on_minigame_complete")
	scene.start()

func _on_minigame_complete(minigame_scene):
	print("Attack complete")
	if is_instance_valid(minigame_scene):
		minigame_scene.queue_free()
	MinigameContainer.visible = false
	emit_signal("player_move_complete", combat_data)
