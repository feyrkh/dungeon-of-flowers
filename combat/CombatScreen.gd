extends Node2D

const SkillButton = preload("res://combat/SkillButton.tscn")
const STATUS_CATEGORY = 4

const bullet_block_sfx = preload("res://sound/mixkit-metallic-sword-strike-2160.wav")
const bullet_strike_sfx = preload("res://sound/mixkit-sword-cutting-flesh-2788.wav")

const end_combat_sfx = preload("res://sound/mixkit-winning-notification-2018.wav")

var combat_data : CombatData

signal start_combat(combat_data)
signal player_move_selected(combat_data, target_enemy, move_data)

signal enemy_move_selected(combat_data, move_data)
signal enemy_move_complete(combat_data, move_data)
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
onready var AllyPortraits = find_node("AllyPortraits")
onready var BulletContainer = find_node("BulletContainer")
onready var ShieldContainer = find_node("ShieldContainer")
onready var MinigameDesiredCenter = find_node("MinigameCenter")

var selected_ally_idx = 0
var selected_category_idx = 0
var restore_category_idx = 0 # set when moving to the 'status' icon, so we can restore back to the previously selected item
var selected_skill
var active_submenu

const UI_DELAY = 0.12

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_tree().root == get_parent():
		# Hack for testing quest stuff without loading a full game
		CombatMgr.is_in_combat = true
		GameData.set_state(GameData.TUTORIAL_ON, false)
		#GameData.set_state(QuestMgr.INTRO, QuestMgr.INTRO_SECOND_COMBAT)
		GameData.set_state(QuestMgr.INTRO, QuestMgr.INTRO_FIRST_COMBAT)
		combat_data = mock_combat_data()
	randomize()
	render_allies()
	render_enemies()
	#adjustStanceButton.visible = true
	#balanceContainer.visible = false
	input_delayed = UI_DELAY
	emit_signal('start_combat', combat_data)
	EventBus.connect("cancel_submenu", self, "_on_Ally_cancel_submenu")
	EventBus.connect("select_submenu_item", self, "_on_Ally_select_submenu_item")
	CombatMgr.connect("new_bullet", self, "_on_new_bullet")
	CombatMgr.connect("player_move_complete", self, "_on_CombatScreen_player_move_complete")
	CombatMgr.connect("start_enemy_turn", self, "_on_CombatScreen_start_enemy_turn")
	CombatMgr.connect("enemy_turn_complete", self, "_on_CombatScreen_enemy_turn_complete")
	CombatMgr.connect("start_player_turn", self, "_on_CombatScreen_start_player_turn")
	CombatMgr.connect("attack_bullet_block", self, "_on_attack_bullet_block")
	CombatMgr.connect("attack_bullet_strike", self, "_on_attack_bullet_strike")
	CombatMgr.connect("enemy_dead", self, "_on_enemy_dead")

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
	if Input.is_action_just_pressed("music_toggle"): # skip turn, temporary debug stuff
		cur_input_phase = InputPhase.NO_INPUT
		CombatMgr.emit_signal("player_turn_complete", combat_data)
		CombatMgr.change_combat_state("start_enemy_turn", combat_data)
	if Input.is_action_just_pressed("select_prev_char"):
		select_next_char(-1)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("select_next_char"):
		select_next_char(1)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("ui_select"): # see below if you change!!!
		open_category_submenu(selected_ally_idx, selected_category_idx, true)
		input_delayed = UI_DELAY
	elif Input.is_action_just_pressed("ui_up"): # see above if you change!!!
		open_category_submenu(selected_ally_idx, selected_category_idx, false)
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
	EventBus.emit_signal("enable_pause_menu")
	var prev_selected = allies[selected_ally_idx]
	var new_selected_ally = null
	for i in range(1, 3):
		var new_selected_ally_idx = (selected_ally_idx + direction*i) % allies.size()
		if new_selected_ally_idx < 0: new_selected_ally_idx += allies.size()
		var next_selected = allies[new_selected_ally_idx]
		if next_selected != null and is_instance_valid(next_selected) and !next_selected.exhausted:
			prev_selected.deselect()
			next_selected.select(selected_category_idx)
			selected_ally_idx = new_selected_ally_idx
			return


func open_category_submenu(ally_idx, category_idx, open_only):
	EventBus.emit_signal("disable_pause_menu")
	if (!open_only and category_idx == STATUS_CATEGORY): # status icon, up should go back to previously selected icon instead
		selected_category_idx = restore_category_idx
		select_next_category(0)
	else:
		cur_input_phase = InputPhase.PLAYER_SELECT_SUBMENU
		var ally = allies[ally_idx]
		ally.open_category_submenu(category_idx)
		QuestMgr.combat_phase = "open_submenu"
		
func _on_Ally_cancel_submenu():
	EventBus.emit_signal("enable_pause_menu")
	cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
	
func select_next_category(direction):
	var cur_ally = allies[selected_ally_idx]
	selected_category_idx = cur_ally.select_category(selected_category_idx, direction)
	EventBus.emit_signal("enable_pause_menu")

func select_status_category():
	EventBus.emit_signal("enable_pause_menu")
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
	for ally in allies:
		if ally != null && is_instance_valid(ally) && ally.is_alive():
			return false
	return true

func mock_combat_data():
	var cd = CombatData.new()
	GameData.setup_allies()
	cd.allies = GameData.allies
	cd.enemies = []
	for i in randi()%3+2:
		cd.enemies.append(EnemyList.get_enemy('random'))
	return cd

func _on_CombatScreen_start_combat(_combat_data):
	print("_on_CombatScreen_start_combat")
	# todo: surprise attacks, screen effects
	#playerInput.visible = false
	#playerSprite.visible = false
	yield(get_tree().create_timer(1.0), "timeout")
	CombatMgr.change_combat_state("start_player_turn", _combat_data)


func _on_CombatScreen_start_player_turn(_combat_data):
	print("_on_CombatScreen_start_player_turn")
	if check_combat_over():
		return
	cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
	selected_ally_idx = 1
	allies[selected_ally_idx].select(selected_category_idx)
	selected_skill = null
	Enemies.decide_enemy_actions()
	QuestMgr.combat_phase = "select_character"

func _on_CombatScreen_player_move_complete(_combat_data):
	print("_on_CombatScreen_player_move_complete")
	#unhighlight_targeted_enemy()
	#disable_enemy_targeting()
	if check_combat_over():
		return
	if check_player_turn_over():
		cur_input_phase = InputPhase.NO_INPUT
		CombatMgr.emit_signal("player_turn_complete", _combat_data)
		CombatMgr.change_combat_state("start_enemy_turn", _combat_data)
	else:
		cur_input_phase = InputPhase.PLAYER_SELECT_CHARACTER
		select_next_char(1)

func check_player_turn_over():
	print("check_player_turn_over")
	for ally in allies:
		if ally != null and is_instance_valid(ally) and !ally.exhausted:
			return false
	return true

func _on_CombatScreen_start_enemy_turn(_combat_data):
	print("_on_CombatScreen_start_enemy_turn")
	yield(get_tree().create_timer(1), "timeout")
	if check_combat_over():
		return
	
	while CombatMgr.combat_animation_delay > 0:
		yield(get_tree().create_timer(CombatMgr.combat_animation_delay), "timeout")
		_on_CombatScreen_start_enemy_turn(_combat_data)
		return
	
	QuestMgr.combat_phase = "enemy_turn"
	CombatMgr.emit_signal("execute_combat_intentions", AllyPortraits.get_live_allies(), Enemies.get_live_enemies())
	while !check_enemy_turn_over():
		yield(get_tree().create_timer(0.5), "timeout")
	while CombatMgr.combat_animation_delay > 0:
		yield(get_tree().create_timer(CombatMgr.combat_animation_delay), "timeout")
	CombatMgr.change_combat_state("enemy_move_complete", _combat_data)
	while CombatMgr.combat_animation_delay > 0:
		yield(get_tree().create_timer(CombatMgr.combat_animation_delay), "timeout")
	CombatMgr.change_combat_state("enemy_turn_complete", _combat_data)

func _on_CombatScreen_enemy_turn_complete(_combat_data):
	print("_on_CombatScreen_enemy_turn_complete")
	while CombatMgr.combat_animation_delay > 0:
		yield(get_tree().create_timer(CombatMgr.combat_animation_delay + 1.2), "timeout")
	#yield(get_tree().create_timer(1.2), "timeout")
	if check_combat_over():
		return
	CombatMgr.change_combat_state("start_player_turn", _combat_data)

func check_enemy_turn_over():
	if enemies_all_dead():
		return true
	var bullets = get_tree().get_nodes_in_group("bullets")
	return bullets.size() <= 0

func _on_enemy_dead(enemy):
	check_combat_over()

func check_combat_over():
	print("check_combat_over")
	if enemies_all_dead():
		AudioPlayerPool.play(end_combat_sfx);
		yield(get_tree().create_timer(0.5), "timeout")
		emit_signal("allies_win", combat_data)
		EventBus.emit_signal("enable_pause_menu")
		return true
	elif allies_all_dead():
		cur_input_phase = InputPhase.NO_INPUT
		emit_signal("allies_lose", combat_data)
		EventBus.emit_signal("enable_pause_menu")
		QuestMgr.play_cutscene("combat_gameover")
		return true
	return false

func _on_Ally_select_submenu_item(submenu, move_data):
	print("_on_Ally_select_submenu_item")
	active_submenu = submenu
	cur_input_phase = InputPhase.PLAYER_SELECT_TARGET
	allies[selected_ally_idx].on_targeting_started(move_data)
	Enemies.start_targeting(move_data, allies[selected_ally_idx])
	AllyPortraits.start_targeting(move_data, allies[selected_ally_idx])
	QuestMgr.combat_phase = "target_enemy"

func _on_Enemies_target_cancelled():
	print("_on_Enemies_target_cancelled")
	active_submenu.on_targeting_cancelled()
	allies[selected_ally_idx].on_targeting_cancelled()
	QuestMgr.combat_phase = "open_submenu"
	
func _on_AllyPortraits_target_cancelled():
	print("_on_AllyPortraits_target_cancelled")
	active_submenu.on_targeting_cancelled()
	allies[selected_ally_idx].on_targeting_cancelled()
	QuestMgr.combat_phase = "open_submenu"
	
func _on_Enemies_single_enemy_target_complete(target_enemy, move_data):
	print("_on_Enemies_single_enemy_target_complete")
	active_submenu.on_targeting_completed()
	allies[selected_ally_idx].on_targeting_completed()
	emit_signal("player_move_selected", combat_data, target_enemy, move_data)

func _on_AllyPortraits_self_target_complete(target_ally, move_data):
	print("_on_AllyPortraits_self_target_complete")
	active_submenu.on_targeting_completed()
	allies[selected_ally_idx].on_targeting_completed()
	emit_signal("player_move_selected", combat_data, target_ally, move_data)

func _on_CombatScreen_player_move_selected(_combat_data, target_enemy, move_data):
	QuestMgr.combat_phase = "opening_minigame"
	Enemies.squish_for_minigame(0.5)
	MinigameContainer.squish_for_minigame(0.5)
	$"ActionVignette/AnimationPlayer".play("fade_in")
	print("Attacking ", target_enemy.data.label, " with skill: ", move_data.label)
	match move_data.type:
		"attack":
			CombatMgr.emit_signal("show_battle_header", allies[selected_ally_idx].data.label+" is attacking "+target_enemy.data.label+"!")
			var scene = move_data.get_move_scene(allies[selected_ally_idx], target_enemy)
			MinigameContainer.add_child(scene)
			MinigameContainer.visible = true
			var MinigameCenter = scene.find_node("MinigameCenter")
			if MinigameCenter:
				var offset = MinigameCenter.position - MinigameDesiredCenter.position
				scene.position -= offset
			else:
				scene.position = (MinigameContainer.rect_size/2)
			scene.connect("minigame_success", target_enemy, "damage_hp")
			scene.connect("minigame_complete", self, "_on_attack_minigame_complete")
			yield(get_tree().create_timer(0.5), "timeout")
			scene.start()
			QuestMgr.combat_phase = "attack_minigame"
		"defend":
			CombatMgr.emit_signal("show_battle_header", allies[selected_ally_idx].data.label+" is defending!")
			var scene = move_data.get_move_scene(allies[selected_ally_idx], target_enemy)
			MinigameContainer.add_child(scene)
			MinigameContainer.visible = true
			var MinigameCenter = scene.find_node("MinigameCenter")
			if MinigameCenter:
				var offset = MinigameCenter.position - MinigameDesiredCenter.position
				scene.position -= offset
			else:
				scene.position = (MinigameContainer.rect_size/2)
			scene.connect("minigame_success", target_enemy, "defend_action")
			scene.connect("minigame_complete", self, "_on_ally_minigame_complete")
			yield(get_tree().create_timer(0.5), "timeout")
			scene.start()
			QuestMgr.combat_phase = "defend_minigame"
		_: 
			CombatMgr.emit_signal("show_battle_header", allies[selected_ally_idx].data.label+" is confused...unknown skill type!")
			yield(get_tree().create_timer(2), "timeout")
			_on_ally_minigame_complete(null)

func _on_attack_minigame_complete(minigame_scene):
	print("Attack complete")
	$"ActionVignette/AnimationPlayer".play_backwards("fade_in")
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.apply_damage()
	QuestMgr.combat_phase = "enemy_take_damage"
	CombatMgr.emit_signal("hide_battle_header")
	Enemies.unsquish_for_minigame(0.5)
	MinigameContainer.unsquish_for_minigame(0.5)
	yield(get_tree().create_timer(0.5), "timeout")
	if is_instance_valid(minigame_scene):
		minigame_scene.queue_free()
	MinigameContainer.visible = false
	CombatMgr.change_combat_state("player_move_complete", combat_data)

func _on_ally_minigame_complete(minigame_scene):
	print("Ally move complete")
	$"ActionVignette/AnimationPlayer".play_backwards("fade_in")
	QuestMgr.combat_phase = "apply_ally_buff"
	CombatMgr.emit_signal("hide_battle_header")
	Enemies.unsquish_for_minigame(0.5)
	yield(get_tree().create_timer(0.5), "timeout")
	if is_instance_valid(minigame_scene):
		minigame_scene.queue_free()
	MinigameContainer.visible = false
	CombatMgr.change_combat_state("player_move_complete", combat_data)

func _on_new_bullet(bullet):
	BulletContainer.add_child(bullet)

func _on_attack_bullet_block():
	AudioPlayerPool.play(bullet_block_sfx)

func _on_attack_bullet_strike(ally_data):
	AudioPlayerPool.play(bullet_strike_sfx)



