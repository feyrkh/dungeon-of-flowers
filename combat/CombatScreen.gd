extends Node2D

const Enemy = preload("res://combat/Enemy.tscn")
const SkillButton = preload("res://combat/SkillButton.tscn")

var combatData : CombatData

signal start_combat(combatData)
signal start_player_turn(combatData)
signal start_enemy_turn(combatData)
signal player_move_selected(combatData, moveData)
signal player_move_complete(combatData, moveData)
signal enemy_move_selected(combatData, moveData)
signal enemy_move_complete(combatData, moveData)
signal enemy_turn_complete(combatData)
signal log_msg(msg)
signal allies_win(combatData)
signal allies_lose(combatData)

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

onready var allies = [find_node("Ally1"), find_node("Ally2"), find_node("Ally3")]

var selected_ally_idx = 0
var selected_category_idx = 0
var targeted_enemy = []
var selected_skill
var accumulated_damage = 0
var expected_damage = 0

const UI_DELAY = 0.12

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if (!combatData):
		combatData = mock_combat_data()
	render_allies()
	render_enemies()
	#adjustStanceButton.visible = true
	#balanceContainer.visible = false
	input_delayed = UI_DELAY
	emit_signal('start_combat', combatData)

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
		InputPhase.PLAYER_SELECT_SUBMENU:
			input_select_submenu()
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

func select_next_char(direction):
	var prev_selected = allies[selected_ally_idx]
	var new_selected_ally_idx = (selected_ally_idx + direction) % allies.size()
	if new_selected_ally_idx < 0: new_selected_ally_idx += allies.size()
	var next_selected = allies[new_selected_ally_idx]
	prev_selected.deselect()
	next_selected.select(selected_category_idx)
	selected_ally_idx = new_selected_ally_idx

func open_category_submenu(ally_idx, category_idx):
	cur_input_phase = InputPhase.PLAYER_SELECT_SUBMENU
	var ally = allies[ally_idx]
	ally.open_category_submenu(category_idx)

func _on_Ally_cancel_submenu():
	cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
	
func select_next_category(direction):
	var cur_ally = allies[selected_ally_idx]
	selected_category_idx = cur_ally.select_category(selected_category_idx, direction)
	
func input_select_submenu():
	pass

func input_select_target():
	pass

func render_allies():
	var allyIdx = 0
	for allyData in combatData.allies:
		allies[allyIdx].setup(allyData)
		allyIdx += 1

func add_enemy(enemyData):
	var positionIdx = 1
	while find_node("EnemyPos"+str(positionIdx)).get_child_count() != 0:
		positionIdx += 1
	var enemy = Enemy.instance(1)
	enemy.setup(enemyData)
	var posNode = find_node("EnemyPos"+str(positionIdx))
	posNode.add_child(enemy)
	positionIdx += 1
	enemy.connect("target_button_entered", self, "_on_Enemy_target_button_entered", [enemy, enemyData])
	enemy.connect("target_button_exited", self, "_on_Enemy_target_button_exited", [enemy, enemyData])
	enemy.connect("target_button_pressed", self, "_on_Enemy_target_button_pressed", [enemy, enemyData])

func render_enemies():
	var enemyNames = {}
	for enemyData in combatData.get_enemies():
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
	
	emit_signal("log_msg", "Uh oh - "+combatData.get_current_ally().label+" ran into "+enemyNamesList)

func enemies_all_dead():
	return get_tree().get_nodes_in_group("enemy").size() == 0

func allies_all_dead():
	return combatData.get_current_ally().hp <= 0

func mock_combat_data():
	var cd = CombatData.new()
	cd.allies = [mock_pharoah(), mock_hipster(), mock_shantae()]
	cd.enemies = []
	for i in randi()%5+1:
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

func _on_CombatScreen_start_combat(_combatData):
	# todo: surprise attacks, screen effects
	#playerInput.visible = false
	#playerSprite.visible = false
	yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("start_player_turn", _combatData)


func _on_CombatScreen_start_player_turn(_combatData):
	emit_signal("log_msg", "It's "+_combatData.get_current_ally().label+"'s turn!")
	cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
	selected_ally_idx = 0
	allies[selected_ally_idx].select(selected_category_idx)
	#playerInput.visible = true
	#playerSprite.visible = true
	selected_skill = null
	#playerSprite.find_node("PlayerPulser").start()
	#render_ally_moves(_combatData)
	#highlight_targeted_enemy()
	#enable_enemy_targeting()

func _on_CombatScreen_player_move_complete(_combatData, moveData):
	#unhighlight_targeted_enemy()
	#disable_enemy_targeting()
	if check_combat_over():
		return
	emit_signal("start_enemy_turn", _combatData)

func _on_CombatScreen_start_enemy_turn(_combatData):
	emit_signal("log_msg", "The enemy is confused...")
	yield(get_tree().create_timer(2), "timeout")
	emit_signal("log_msg", "The enemy just stands there!")
	emit_signal("enemy_turn_complete", _combatData)

func _on_CombatScreen_enemy_turn_complete(_combatData):
	yield(get_tree().create_timer(0.5), "timeout")
	if check_combat_over():
		return
	emit_signal("start_player_turn", _combatData)

func check_combat_over():
	if enemies_all_dead():
		emit_signal("allies_win", combatData)
		emit_signal("log_msg", "The allies win!")
		#Util.fadeout(self, 1.5)
		yield(get_tree().create_timer(2), "timeout")
		queue_free()
		return true
	elif allies_all_dead():
		emit_signal("allies_lose", combatData)
		emit_signal("log_msg", "The allies lost....")
		#Util.fadeout(self, 1.5)
		yield(get_tree().create_timer(2), "timeout")
		queue_free()
		return true


