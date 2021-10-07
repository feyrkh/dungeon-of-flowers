extends Node

signal cutscene_start
signal cutscene_end

var INTRO = "intro"
var INTRO_INTRODUCED_GRIAS = "intro_1"
var INTRO_FIRST_COMBAT = "intro_2"

var cutscene

func _ready():
	self.pause_mode = PAUSE_MODE_PROCESS

func check_quest_progress():
	if check_introduction(): return

func check_introduction():
	if !GameData.get_state(GameData.TUTORIAL_ON):
		return false
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
