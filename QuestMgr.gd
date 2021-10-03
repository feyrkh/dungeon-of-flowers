extends Node

signal cutscene_start
signal cutscene_end

var INTRO = "intro"
var INTRO_INTRODUCED_GRIAS = "intro_1"
var INTRO_INTRODUCED_ECHINACEA = "intro_2"

var cutscene

func _ready():
	self.pause_mode = PAUSE_MODE_PROCESS

func check_quest_progress():
	if check_introduction(): return

func check_introduction():
	if !GameData.get_setting(GameData.TUTORIAL_ON):
		return false
	if GameData.get_setting(INTRO, 0) == 0:
		play_cutscene(INTRO_INTRODUCED_GRIAS)
		yield(cutscene, "timeline_end")
		GameData.set_state(INTRO, INTRO_INTRODUCED_GRIAS)
		return true

func play_cutscene(_cutscene_name):
	if cutscene and is_instance_valid(cutscene):
		cutscene.queue_free()
	get_tree().paused = true
	emit_signal("cutscene_start", _cutscene_name)
	cutscene = Dialogic.start(_cutscene_name)
	cutscene.connect("timeline_end", self, "on_timeline_end")
	add_child(cutscene)

func on_timeline_end(timeline_name):
	print("cutscene ended: ", timeline_name)
	emit_signal("cutscene_end", timeline_name)
	cutscene = null
	get_tree().paused = false
