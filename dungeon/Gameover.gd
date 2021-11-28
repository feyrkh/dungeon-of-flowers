extends Node2D

func _ready():
	QuestMgr.play_cutscene("combat_gameover")
	yield(QuestMgr, "cutscene_end")
	get_tree().change_scene("res://menu/MainMenu.tscn")
	
