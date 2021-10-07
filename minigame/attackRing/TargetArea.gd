extends Area2D

export(float) var multiplier = 1
var target_color

func clear_target():
	get_parent().clear_target()
