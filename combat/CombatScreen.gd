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

onready var adjustStanceButton = find_node("AdjustStance")
onready var balanceContainer = find_node("BalanceContainer")
onready var attackContainer = find_node("AttackContainer")
onready var stanceHeight = find_node("Height")
onready var stanceSidestep = find_node("Sidestep")
onready var stanceAngle = find_node("Angle")
onready var stanceNewHeight = find_node("NewHeight")
onready var stanceNewSidestep = find_node("NewSidestep")
onready var stanceNewAngle = find_node("NewAngle")
onready var acceptStance = find_node("AcceptStance")
onready var playerInput = find_node("PlayerInput")
onready var movesContainer = find_node("MovesContainer")
onready var playerSprite = find_node("PlayerSprite")
onready var allyName = find_node("Name")
onready var allyClass = find_node("Class")
onready var allyHp = find_node("Hp")
onready var allyMp = find_node("Mp")
onready var allyBalance = find_node("Balance")
onready var combatLog = find_node("CombatLog")

var enemy_targeting_enabled = false
var targeted_enemy = []
var selected_skill
var accumulated_damage = 0
var expected_damage = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if (!combatData):
		combatData = mock_combat_data()
	render_allies()
	render_enemies()
	#adjustStanceButton.visible = true
	#balanceContainer.visible = false
	emit_signal('start_combat', combatData)

func render_allies():
	playerSprite.texture = combatData.get_current_ally().texture
	allyName.text = combatData.get_current_ally().label
	allyClass.text = combatData.get_current_ally().className
	allyHp.text = str(combatData.get_current_ally().hp)+"/"+str(combatData.get_current_ally().max_hp)
	allyMp.text = str(combatData.get_current_ally().mp)+"/"+str(combatData.get_current_ally().max_mp)
	allyBalance.text = str(combatData.get_current_ally().balance)+"/"+str(combatData.get_current_ally().max_balance)

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

func render_ally_moves(combatData):
	Util.delete_children(movesContainer)
	for move in combatData.get_current_ally().moves:
		var skillButton = Util.config(SkillButton.instance(), {
			"moveData": move,
			"combatData": combatData
		})
		movesContainer.add_child(skillButton)
		skillButton.connect("skill_triggered", self, "_on_skill_triggered", [skillButton])
	movesContainer.visible = true

func highlight_targeted_enemy():
	for enemy in get_tree().get_nodes_in_group("enemy"): 
		enemy.unhighlight()
	if targeted_enemy.size() > 0:
		targeted_enemy[0].highlight()

func unhighlight_targeted_enemy():
	for enemy in get_tree().get_nodes_in_group("enemy"): 
		enemy.unhighlight()

func unhighlight_skills():
	for skillButton in get_tree().get_nodes_in_group("skill_button"):
		skillButton.unhighlight()

func enable_enemy_targeting():
	enemy_targeting_enabled = true
	highlight_targeted_enemy()

func disable_enemy_targeting():
	targeted_enemy = []
	enemy_targeting_enabled = false
	unhighlight_targeted_enemy()

func trigger_attack_skill(enemy:Enemy, skill):
	unhighlight_targeted_enemy()
	disable_enemy_targeting()
	unhighlight_skills()
	print("Attacking "+enemy.data.label+" with "+skill.name)
	var attackScene = skill.get_attack_scene(enemy)
	movesContainer.visible = false
	#playerInput.visible = false
	#combatLog.visible = false
	Util.delete_children(attackContainer)
	attackContainer.visible = true
	attackContainer.add_child(attackScene)
	yield(get_tree().create_timer(0.5), "timeout")
	accumulated_damage = 0
	expected_damage = skill.base_damage * skill.strikes
	attackScene.connect("minigame_success", self, "_on_skill_damage", [skill, enemy])
	attackScene.start()
	yield(attackScene, "minigame_complete")
	attackContainer.visible = false
	var msg:String
	if accumulated_damage > 0:
		msg = skill.damageFormat
		if accumulated_damage > expected_damage*1.5:
			msg = msg + " " + skill.strongFormat
		elif accumulated_damage < expected_damage*0.6:
			msg = msg + " " + skill.weakFormat
	else:
		msg = skill.missFormat
	msg = msg.format({
		"player": combatData.get_current_ally().label,
		"enemy": enemy.data.label,
		"damage": accumulated_damage,
	})
	emit_signal("log_msg", msg)
	#combatLog.visible = true
	if enemy.data.hp <= 0:
		#Util.fadeout(enemy, 0.5)
		yield(get_tree().create_timer(0.7), "timeout")
		if enemy != null:
			enemy.queue_free()
		emit_signal("log_msg", enemy.data.label+" dies")
	yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("player_move_complete", combatData, skill)

func _on_skill_damage(damageMultiplier:float, skill, enemy:Enemy):
	var damage = skill.base_damage * damageMultiplier
	accumulated_damage += damage
	if enemy.data.hp > 0: 
		enemy.damage_hp(damage)

func mock_combat_data():
	var ally
	match randi()%4:
		0: ally = mock_pharoah()
		1: ally = mock_hipster()
		2: ally = mock_shantae()
		3: ally = mock_vega()
	var cd = CombatData.new()
	cd.allies = [ally]
	cd.enemies = []
	for i in randi()%5+1:
		cd.enemies.append(EnemyList.get_enemy('random'))
	return cd

func mock_pharoah():
	var ally = AllyData.new()
	ally.label = "Imhotep"
	ally.className = "Pharoah"
	ally.max_hp = 100
	ally.hp = 100
	ally.mp = 20
	ally.max_mp = 20
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
	ally.hp = 100
	ally.mp = 20
	ally.max_mp = 20
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
	ally.hp = 100
	ally.mp = 20
	ally.max_mp = 20
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
	ally.hp = 100
	ally.mp = 20
	ally.max_mp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero4.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('kick'),
		MoveList.get_move('headbutt'),
	]
	return ally


func _on_AdjustStance_pressed():
	adjustStanceButton.visible = false
	balanceContainer.visible = true
	stanceHeight.text = str(combatData.get_current_ally().stance_height)
	stanceSidestep.text = str(combatData.get_current_ally().stance_sidestep)
	stanceAngle.text = str(combatData.get_current_ally().stance_angle)
	stanceNewHeight.value = (combatData.get_current_ally().stance_height)
	stanceNewSidestep.value = (combatData.get_current_ally().stance_sidestep)
	stanceNewAngle.value = (combatData.get_current_ally().stance_angle)
	update_stance_change_cost()


func _on_CancelStance_pressed():
	adjustStanceButton.visible = true
	balanceContainer.visible = false


func _on_AcceptStance_pressed():
	adjustStanceButton.visible = true
	balanceContainer.visible = false
	var cost = calculate_stance_change_cost()
	combatData.get_current_ally().balance -= cost
	combatData.get_current_ally().stance_height = stanceNewHeight.value
	combatData.get_current_ally().stance_sidestep = stanceNewSidestep.value
	combatData.get_current_ally().stance_angle = stanceNewAngle.value

func _on_NewHeight_value_changed(value):
	update_stance_change_cost()

func _on_NewSidestep_value_changed(value):
	update_stance_change_cost()

func _on_NewAngle_value_changed(value):
	update_stance_change_cost()

func update_stance_change_cost():
	var cost = calculate_stance_change_cost()
	if cost != 0:
		acceptStance.text = "Accept (cost: "+str(cost)+")"
	else:
		acceptStance.text = "No change"
	acceptStance.disabled = cost > combatData.get_current_ally().balance

func calculate_stance_change_cost():
	var cost = abs(combatData.get_current_ally().stance_height - stanceNewHeight.value)
	cost += abs(combatData.get_current_ally().stance_sidestep - stanceNewSidestep.value)
	cost += abs(combatData.get_current_ally().stance_angle - stanceNewAngle.value)
	cost = cost * cost
	return cost

func _on_CombatScreen_start_combat(combatData):
	# todo: surprise attacks, screen effects
	playerInput.visible = false
	playerSprite.visible = false
	yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("start_player_turn", combatData)


func _on_CombatScreen_start_player_turn(combatData):
	emit_signal("log_msg", "It's "+combatData.get_current_ally().label+"'s turn!")
	playerInput.visible = true
	playerSprite.visible = true
	selected_skill = null
	#playerSprite.find_node("PlayerPulser").start()
	render_ally_moves(combatData)
	#highlight_targeted_enemy()
	#enable_enemy_targeting()

func _on_CombatScreen_player_move_complete(combatData, moveData):
	unhighlight_targeted_enemy()
	disable_enemy_targeting()
	if check_combat_over():
		return
	emit_signal("start_enemy_turn", combatData)
	
func _on_skill_triggered(combatData, moveData, skillNode):
	unhighlight_skills()
	if selected_skill != moveData: 
		skillNode.highlight()
		selected_skill = moveData
	else:
		selected_skill = null
	if selected_skill and moveData.targets_enemy:
		enable_enemy_targeting()
	else:
		disable_enemy_targeting()

func _on_Enemy_target_button_exited(enemyNode, enemyData):
	if targeted_enemy.size() > 1 and targeted_enemy[0] == enemyNode:
		targeted_enemy.erase(enemyNode)
		highlight_targeted_enemy()
	else:
		targeted_enemy.erase(enemyNode)
	if targeted_enemy.size() == 0:
		unhighlight_targeted_enemy()

func _on_Enemy_target_button_entered(enemyNode, enemyData):
	if !enemy_targeting_enabled: 
		return
	targeted_enemy.push_front(enemyNode)
	highlight_targeted_enemy()

func _on_Enemy_target_button_pressed(enemyNode, enemyData):
	if targeted_enemy.size() > 0:
		trigger_attack_skill(targeted_enemy[0], selected_skill)

func _on_CombatScreen_start_enemy_turn(combatData):
	emit_signal("log_msg", "The enemy is confused...")
	yield(get_tree().create_timer(2), "timeout")
	emit_signal("log_msg", "The enemy just stands there!")
	emit_signal("enemy_turn_complete", combatData)

func _on_CombatScreen_enemy_turn_complete(combatData):
	yield(get_tree().create_timer(0.5), "timeout")
	if check_combat_over():
		return
	emit_signal("start_player_turn", combatData)

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
