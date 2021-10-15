extends Node

signal cutscene_start
signal cutscene_end

const BG_CHAR = preload("res://dialogic/BgChar.tscn")

var INTRO = "intro"
var INTRO_INTRODUCED_GRIAS = "intro_1"
var INTRO_FIRST_COMBAT = "intro_2"
var INTRO_SECOND_COMBAT = "intro_3"
var INTRO_COMPLETE = "intro_complete"

var cutscene
var cutscene_bg_chars 
var combat_phase setget set_combat_phase
var skill_menu_open setget set_skill_menu_open

func _ready():
	self.pause_mode = PAUSE_MODE_PROCESS
	cutscene_bg_chars = Node2D.new()
	add_child(cutscene_bg_chars)
	EventBus.connect("pre_save_game", self, "on_pre_save_game")
	EventBus.connect("post_load_game", self, "on_post_load_game")

func on_pre_save_game():
	GameData.set_state("QMGR_combat_phase", combat_phase)
	GameData.set_state("QMGR_skill_menu_open", skill_menu_open)

func on_post_load_game():
	combat_phase = GameData.get_state("QMGR_combat_phase")
	skill_menu_open = GameData.get_state("QMGR_skill_menu_open")

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
				GameData.set_state(INTRO, INTRO_SECOND_COMBAT)
			else:
				EventBus.emit_signal("hide_tutorial")
		INTRO_SECOND_COMBAT:
			if combat_phase == "enemy_turn":
				EventBus.emit_signal("show_tutorial", "UsingShield", false)


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
				GameData.set_state(GameData.STEP_COUNTER, 0)
				play_cutscene(INTRO_FIRST_COMBAT)
				yield(cutscene, "timeline_end")
				GameData.set_state(INTRO, INTRO_FIRST_COMBAT)
				CombatMgr.trigger_combat("tutorial")
				return true
		INTRO_SECOND_COMBAT:
			if GameData.get_state(GameData.STEP_COUNTER, 0) == 6:
				play_cutscene(INTRO_SECOND_COMBAT)
				yield(cutscene, "timeline_end")
				GameData.allies[0] = GameData.new_char_echincea()
				GameData.allies[1].shields = [{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(0, -160), "scale": Vector2(2.0, 2.0)}]
				CombatMgr.trigger_combat("tutorial2")

func play_cutscene(_cutscene_name):
	if cutscene and is_instance_valid(cutscene):
		cutscene.queue_free()
	get_tree().paused = true
	emit_signal("cutscene_start", _cutscene_name)
	EventBus.emit_signal("disable_pause_menu")
	cutscene = Dialogic.start(_cutscene_name)
	cutscene.connect("timeline_end", self, "on_timeline_end")
	cutscene.connect("dialogic_signal", GameData, "on_dialogic_signal")
	cutscene.connect("dialogic_signal", self, "on_dialogic_signal")
	add_child(cutscene)

func on_timeline_end(timeline_name):
	print("cutscene ended: ", timeline_name)
	Util.delete_children(cutscene_bg_chars)
	emit_signal("cutscene_end", timeline_name)
	EventBus.emit_signal("enable_pause_menu")
	cutscene = null
	get_tree().paused = false

func on_dialogic_signal(val:String):
	# char_join$res://img/slime.jpg$sneakleft$0.5$300
	# char_join$<img path>$<move style>$<number of image widths to move>$<offset height pixels>
	if val.begins_with("char_join"):
		var bits = val.split("$")
		var new_char = BG_CHAR.instance()
		var offset_y = int(bits[4])
		new_char.img_path = bits[1]
		new_char.pos = bits[2]
		new_char.pos_offset = Vector2(0, -offset_y)
		new_char.target_position_offset_widths = float(bits[3])
		cutscene_bg_chars.add_child(new_char)


func can_enter_combat():
	if GameData.get_state(GameData.TUTORIAL_ON, false) and str(GameData.get_state(INTRO)) != INTRO_FIRST_COMBAT:
		return false
	return true

func on_tile_move_complete():
	GameData.set_state("step_counter", GameData.get_state("step_counter", 0)+1)
	check_quest_progress()
