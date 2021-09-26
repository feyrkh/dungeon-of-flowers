extends Node2D

func setup(ally, shield_data):
	global_position = ally.get_target(0) + shield_data.get("pos", Vector2.ZERO)
	scale = shield_data.get("scale", Vector2.ONE)
