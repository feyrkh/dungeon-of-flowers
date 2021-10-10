extends Control
class_name BaseMenuItem

export(Color) var highlight_color = Color.palevioletred
var disabled setget set_disabled, get_disabled
export(bool) var increment_sfx = true

func set_disabled(val):
	disabled = val

func get_disabled():
	return disabled

func menu_selected(menu):
	if !get_disabled():
		modulate = highlight_color
	else:
		modulate = highlight_color.darkened(0.4)

func menu_deselected(menu):
	if !get_disabled():
		modulate = Color.white
	else:
		modulate = Color.darkgray
