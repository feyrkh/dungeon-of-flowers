extends Node

signal cutscene_start
signal cutscene_end

const BG_CHAR = preload("res://dialogic/BgChar.tscn")

var INTRO = "intro"
var INTRO_INTRODUCED_GRIAS = "intro_1"
var INTRO_FIRST_COMBAT = "intro_2"
var INTRO_NEED_SHIELD = "intro_need_shield"
var INTRO_MULTI_ATTACK = "intro_multiattack"
var INTRO_ENCHINACEA = "intro_chin"
var INTRO_SECOND_COMBAT = "intro_3"
var INTRO_HEAL_SKILL = "intro_4"
var INTRO_THIRD_COMBAT = "intro_5"
var INTRO_COMPLETE = "intro_complete"

var cutscene
var cutscene_bg_chars
var combat_phase setget set_combat_phase
var skill_menu_open setget set_skill_menu_open
var pollen_spread_enabled

func _ready():
	self.pause_mode = PAUSE_MODE_PROCESS
	cutscene_bg_chars = Node2D.new()
	add_child(cutscene_bg_chars)
	EventBus.connect("pre_save_game", self, "on_pre_save_game")
	EventBus.connect("pre_load_game", self, "on_pre_load_game")
	EventBus.connect("post_load_game", self, "on_post_load_game")
	GameData.connect("state_updated", self, "on_state_updated")
	EventBus.connect("acquire_item", self, "on_acquire_item")

func on_acquire_item(item, amt):
	match item:
		"shield":
			# Shield acquired for the first time, unlock the defense skill
			GameData.allies[1].moves[0].disabled = true
			GameData.allies[1].moves.append(MoveList.get_move("turtle"))

func on_state_updated(key, old_value, new_value):
#	match key:
#		"intro":
#			match new_value:
#				INTRO_SECOND_COMBAT:
					pass

func on_pre_save_game():
	GameData.set_state("QMGR_combat_phase", combat_phase)
	GameData.set_state("QMGR_skill_menu_open", skill_menu_open)
	GameData.set_state("QMGR_pollen_spread_enabled", pollen_spread_enabled)

func on_pre_load_game():
	if cutscene:
		cutscene.queue_free()
		cutscene = null
	Util.delete_children(cutscene_bg_chars)

func on_post_load_game():
	combat_phase = GameData.get_state("QMGR_combat_phase")
	skill_menu_open = GameData.get_state("QMGR_skill_menu_open")
	pollen_spread_enabled = GameData.get_state("QMGR_pollen_spread_enabled", true)

func set_combat_phase(phase):
	combat_phase = phase
	print("Quest combat_phase: ", combat_phase)
	check_quest_progress()

func set_skill_menu_open(val):
	skill_menu_open = val
	print("Quest skill_menu_open: ", val)
	check_quest_progress()

func check_quest_progress():
	if check_introduction(): return

func check_introduction():
	if !GameData.get_state(GameData.TUTORIAL_ON):
		return false
	if CombatMgr.is_in_combat:
		return check_combat_introduction()
	else:
		return check_noncombat_introduction()

func check_combat_introduction():
	match GameData.get_state(INTRO, 0):
		INTRO_FIRST_COMBAT:
			if combat_phase == "select_character":
				EventBus.emit_signal("show_tutorial", "SelectCategory", false)
			elif combat_phase == "open_submenu":
				if skill_menu_open == "attack":
					EventBus.emit_signal("show_tutorial", "SelectSlashSkill", false)
				else:
					EventBus.emit_signal("show_tutorial", "WrongCategoryFight", false)
			elif combat_phase == "target_enemy":
				EventBus.emit_signal("show_tutorial", "TargetEnemy", false)
			elif combat_phase == "attack_minigame":
				EventBus.emit_signal("show_tutorial", "AttackMinigame", true)
			#elif combat_phase == "enemy_take_damage":
			#	EventBus.emit_signal("show_tutorial", "EnemyTakeDamage", false)
			elif combat_phase == "enemy_turn":
				EventBus.emit_signal("show_tutorial", "EnemyAttack", false)
				GameData.set_state(INTRO, INTRO_NEED_SHIELD)
			else:
				EventBus.emit_signal("hide_tutorial")
		INTRO_SECOND_COMBAT:
			if combat_phase == "select_character":
				if CombatMgr.combat.selected_ally_idx == 1:
					EventBus.emit_signal("show_tutorial", "SelectDefendCategory", false)
				else:
					EventBus.emit_signal("hide_tutorial")
			elif combat_phase == "open_submenu" and CombatMgr.combat.selected_ally_idx == 1:
				if skill_menu_open != "defend":
					EventBus.emit_signal("show_tutorial", "WrongCategoryDefend", false)
				elif skill_menu_open == "defend":
					EventBus.emit_signal("show_tutorial", "SelectDefendSkill", false)
			else:
				EventBus.emit_signal("hide_tutorial")
			if combat_phase == "enemy_turn":
				EventBus.emit_signal("show_tutorial", "UsingShield", false)
				GameData.allies[1].moves[0].disabled = false
				GameData.set_state(INTRO, INTRO_MULTI_ATTACK)
		INTRO_MULTI_ATTACK:
			if combat_phase == "select_character":
				if GameData.allies[1].get_shields().size() == 0:
					EventBus.emit_signal("show_tutorial", "MultiAttack_NoShield", false)
				else:
					EventBus.emit_signal("show_tutorial", "MultiAttack_WithShield", false)
				GameData.set_state(INTRO, INTRO_ENCHINACEA)

				#GameData.allies[0].moves.append(MoveList.get_move("poultice"))
				#GameData.allies[0].moves[0].disabled = true
#				GameData.set_state(INTRO, INTRO_HEAL_SKILL)
#		INTRO_HEAL_SKILL:
#			if combat_phase == "select_character":
#				if CombatMgr.combat.selected_ally_idx == 0:
#					EventBus.emit_signal("show_tutorial", "SelectSkillCategory", false)
#				else:
#					EventBus.emit_signal("hide_tutorial")
#			elif combat_phase == "open_submenu" and CombatMgr.combat.selected_ally_idx == 0:
#				if skill_menu_open != "skill":
#					EventBus.emit_signal("show_tutorial", "WrongCategorySkill", false)
#				elif skill_menu_open == "skill":
#					EventBus.emit_signal("show_tutorial", "SelectPoulticeSkill", false)
#			elif combat_phase == "enemy_turn":
#				GameData.allies[0].moves[0].disabled = false
#			else:
#				EventBus.emit_signal("hide_tutorial")

func check_noncombat_introduction():
	pass
#	match GameData.get_state(INTRO, 0):
#		0:
#			if GameData.get_state(GameData.STEP_COUNTER, 0) == 1:
#				play_cutscene(INTRO_INTRODUCED_GRIAS)
#				yield(cutscene, "timeline_end")
#				GameData.set_state(INTRO, INTRO_INTRODUCED_GRIAS)
#				return true
#		INTRO_INTRODUCED_GRIAS:
#			if GameData.get_state(GameData.STEP_COUNTER, 0) == 8:
#				GameData.set_state(GameData.STEP_COUNTER, 0)
#				play_cutscene(INTRO_FIRST_COMBAT)
#				yield(cutscene, "timeline_end")
#				#GameData.set_state(INTRO, INTRO_FIRST_COMBAT)
#				CombatMgr.trigger_combat("tutorial")
#				return true
#		INTRO_NEED_SHIELD:
#			play_cutscene(INTRO_NEED_SHIELD)
#		INTRO_ENCHINACEA:
#			#if GameData.get_state(GameData.STEP_COUNTER, 0) == 6:
#			if false:
#				play_cutscene(INTRO_SECOND_COMBAT)
#				yield(cutscene, "timeline_end")
#				GameData.allies[0] = GameData.new_char_echincea()
#				#GameData.allies[1].shields = [{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(0, -160), "scale": Vector2(2.0, 2.0)}]
#				GameData.allies[1].moves[0].disabled = true
#				GameData.allies[1].moves.append(MoveList.get_move("bodyguard"))
#				#GameData.set_state(INTRO, INTRO_SECOND_COMBAT)
#				CombatMgr.trigger_combat("tutorial2")

func play_cutscene(_cutscene_name):
	if cutscene and is_instance_valid(cutscene):
		cutscene.queue_free()
	get_tree().paused = true
	emit_signal("cutscene_start", _cutscene_name)
	EventBus.emit_signal("disable_pause_menu")
	EventBus.emit_signal("hide_minimap")
	cutscene = Dialogic.start(_cutscene_name)
	cutscene.connect("timeline_end", self, "on_timeline_end")
	cutscene.connect("dialogic_signal", GameData, "on_dialogic_signal")
	cutscene.connect("dialogic_signal", self, "on_dialogic_signal")
	add_child(cutscene)

func on_timeline_end(timeline_name):
	print("cutscene ended: ", timeline_name)
	Util.delete_children(cutscene_bg_chars)
	#emit_signal("cutscene_end", timeline_name)
	EventBus.emit_signal("enable_pause_menu")
	EventBus.emit_signal("show_minimap")
	cutscene = null
	get_tree().paused = false
	emit_signal("cutscene_end", timeline_name)

func on_dialogic_signal(val:String):
	# char_join$res://art_exports/characters/enemy_puddle.png$sneakleft$0.5$300
	# char_join$<img path>$<move style>$<number of image widths to move>$<offset height pixels>
	if val.begins_with("char_join"):
		var bits = val.split("$")
		var new_char = BG_CHAR.instance()
		new_char.img_path = bits[1]
		if !new_char.img_path.begins_with("res:"):
			new_char.img_path = "res://art_exports/characters/"+new_char.img_path+".png"
		var config = JSON.parse(bits[2]).result
		Util.config(new_char, config)
#		new_char.pos = bits[2]
#		var offset_y = int(bits[4])
#		new_char.pos_offset = Vector2(0, -offset_y)
#		new_char.target_position_offset_widths = float(bits[3])
		cutscene_bg_chars.add_child(new_char)


func can_enter_combat():
	return GameData.get_state(GameData.RANDOM_COMBAT_ENABLED, true)

func on_tile_move_complete():
	GameData.set_state("_step_counter", GameData.get_state("_step_counter", 0)+1)
	check_quest_progress()
