extends Control

export(String) var yes_text = "Yes"
export(String) var no_text = "No"
export(bool) var cur_choice = false setget set_cur_choice

func set_cur_choice(val):
	cur_choice = val
	update_text()

onready var Label = self

func _ready():
	update_text()
	visible = false

func toggle_choice():
	cur_choice = !cur_choice
	update_text()

func update_text():
	if cur_choice:
		Label.text = "< "+yes_text+" >"
	else:
		Label.text = "< "+no_text+" >"
