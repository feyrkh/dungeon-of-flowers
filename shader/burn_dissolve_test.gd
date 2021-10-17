extends Node2D


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		var refresh_material = load("res://shader/reverse_burn_dissolve.material")
		$Enemy.find_node("Sprite").material = refresh_material
		$Enemy.find_node("Sprite").material.set_shader_param("offset", randf()*10)
		$Enemy.find_node("Sprite").material.set_shader_param("start_time", OS.get_ticks_msec() / 1000.0)
