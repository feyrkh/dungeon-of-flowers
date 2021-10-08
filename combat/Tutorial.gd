extends Control

var tutorial_paused = false

func _ready():
	on_hide_tutorial()
	EventBus.connect("show_tutorial", self, "on_show_tutorial")
	EventBus.connect("hide_tutorial", self, "on_hide_tutorial")

func on_show_tutorial(tooltip_name, pause_game):
	on_hide_tutorial()
	var tutorial = find_node(tooltip_name)
	if tutorial:
		tutorial.visible = true
		if pause_game:
			tutorial_paused = true
			get_tree().paused = true
			EventBus.emit_signal("disable_pause_menu")
		if tutorial.has_method("show_tutorial"):
			tutorial.show_tutorial()

func on_hide_tutorial():
	for child in get_children():
		child.visible = false
	if tutorial_paused:
		get_tree().paused = false
		EventBus.emit_signal("enable_pause_menu")
	
