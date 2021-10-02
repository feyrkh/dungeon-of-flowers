extends Control
class_name BaseMenuItem

export(Color) var highlight_color = Color.palevioletred

func menu_selected(menu):
	modulate = highlight_color

func menu_deselected(menu):
	modulate = Color.white
