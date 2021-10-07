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

func get_highest_multiplier():
	var max_multiplier = 0
	for area in in_areas:
		if area.multiplier > max_multiplier:
			max_multiplier = area.multiplier
	return max_multiplier

func _on_Area2D_area_exited(area):
	in_areas.erase(area)
	update_color()
