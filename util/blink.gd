extends Timer



func _on_Timer_timeout():
	get_parent().visible = !get_parent().visible
