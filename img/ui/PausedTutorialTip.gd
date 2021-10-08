extends PanelContainer

onready var TutorialTipResume = load("res://util/TutorialTipResume.tscn")

func show_tutorial():
	var unpause = TutorialTipResume.instance()
	get_parent().add_child(unpause)
	unpause.rect_global_position = Vector2(rect_global_position.x + rect_size.x/2 - unpause.rect_size.x/2, rect_global_position.y + rect_size.y)
	unpause.visible = true
	unpause.start()
