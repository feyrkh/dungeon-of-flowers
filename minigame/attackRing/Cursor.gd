extends Sprite

var in_areas = []
onready var default_color = self.modulate

func _on_Area2D_area_entered(area):
	in_areas.append(area)
	update_color()

func update_color():
	var max_multiplier = 0
	var new_color = default_color
	for area in in_areas:
		if area.multiplier > max_multiplier:
			max_multiplier = area.multiplier
			new_color = area.target_color
	self.modulate = new_color
	#print("new color: ", new_color, "; new multiplier: ", max_multiplier)

func get_highest_multiplier(clear_target):
	var max_multiplier = 0
	var max_area = null
	for area in in_areas:
		if area.multiplier > max_multiplier:
			max_multiplier = area.multiplier
			max_area = area
	if clear_target and max_area:
		max_area.clear_target(max_multiplier)
	return max_multiplier

func _on_Area2D_area_exited(area):
	var left_strike_zone = true
	in_areas.erase(area)
	for in_area in in_areas:
		if in_area.get_parent() == area.get_parent():
			left_strike_zone = false
	if left_strike_zone:
		area.get_parent().clear_target(-1)
	update_color()
