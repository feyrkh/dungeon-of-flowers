extends Node

signal cutscene_start
signal cutscene_end

var INTRO = "intro"
var INTRO_INTRODUCED_GRIAS = "intro_1"
var INTRO_FIRST_COMBAT = "intro_2"
var INTRO_FIRST_COMBAT_FINISH = "intro_3"

var cutscene
var combat_phase setget set_combat_phase
var skill_menu_open setget set_skill_menu_open

func _ready():
	self.pause_mode = PAUSE_MODE_PROCESS

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
					EventBus.emit_signal("show_tutorial", "WrongCategory", false)
			elif combat_phase == "target_enemy":
				EventBus.emit_signal("show_tutorial", "TargetEnemy", false)
			elif combat_phase == "attack_minigame":
				EventBus.emit_signal("show_tutorial", "AttackMinigame", true)
			#elif combat_phase == "enemy_take_damage":
			#	EventBus.emit_signal("show_tutorial", "EnemyTakeDamage", false)
			elif combat_phase == "enemy_turn":
				EventBus.emit_signal("show_tutorial", "EnemyAttack", false)
				GameData.set_state(INTRO, INTRO_FIRST_COMBAT_FINISH)
			else:
				EventBus.emit_signal("hide_tutorial")

func check_noncombat_introduction():
	match GameData.get_state(INTRO, 0):
		0:
			if GameData.get_state(GameData.STEP_COUNTER, 0) == 1:
				play_cutscene(INTRO_INTRODUCED_GRIAS)
				yield(cutscene, "timeline_end")
				GameData.set_state(INTRO, INTRO_INTRODUCED_GRIAS)
				return true
		INTRO_INTRODUCED_GRIAS: 
			if GameData.get_state(GameData.STEP_COUNTER, 0) == 4:
				play_cutscene(INTRO_FIRST_COMBAT)
				yield(cutscene, "timeline_end")
				GameData.set_state(INTRO, INTRO_FIRST_COMBAT)
				CombatMgr.trigger_combat("tutorial")
				return true

func play_cutscene(_cutscene_name):
	if cutscene and is_instance_valid(cutscene):
		cutscene.queue_free()
	get_tree().paused = true
	emit_signal("cutscene_start", _cutscene_name)
	EventBus.emit_signal("disable_pause_menu")
	cutscene = Dialogic.start(_cutscene_name)
	cutscene.connect("timeline_end", self, "on_timeline_end")
	cutscene.connect("dialogic_signal", GameData, "on_dialogic_signal")
	add_child(cutscene)

func on_timeline_end(timeline_name):
	print("cutscene ended: ", timeline_name)
	emit_signal("cutscene_end", timeline_name)
	EventBus.emit_signal("enable_pause_menu")
	cutscene = null
	get_tree().paused = false

func can_enter_combat():
	if GameData.get_state(GameData.TUTORIAL_ON, false) and str(GameData.get_state(INTRO)) != INTRO_FIRST_COMBAT:
		return false
	return true

func on_tile_move_complete():
	GameData.set_state("step_counter", GameData.get_state("step_counter", 0)+1)
	check_quest_progress()
