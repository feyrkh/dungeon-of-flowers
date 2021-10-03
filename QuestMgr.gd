extends Node

signal cutscene_start
signal cutscene_end

var INTRO = "intro"
var INTRO_INTRODUCED_GRIAS = "intro_1"
var INTRO_INTRODUCED_ECHINACEA = "intro_2"

var cutscene

func check_quest_progress():
	if check_introduction(): return

func check_introduction():
	if GameData.get_state(INTRO, 0) == 0:
		play_cutscene(INTRO_INTRODUCED_GRIAS)
		yield(cutscene, "timeline_end")
		GameData.set_state(INTRO, INTRO_INTRODUCED_GRIAS)

func play_cutscene(cutscene_name):
	if cutscene and is_instance_valid(cutscene):
		cutscene.queue_free()
	emit_signal("cutscene_start")
	cutscene = Dialogic.start(cutscene_name)
	cutscene.connect("timeline_end", self, "on_timeline_end")
	add_child(cutscene)

func on_timeline_end():
	emit_signal("cutscene_end")
