extends OmniLight

export var min_energy = 1.0
export var max_energy = 1.0
export var min_range = 6.0
export var max_range = 9.0
export var time_between_flicker = 0.1
export var min_time_between_direction_change = 1
export var max_time_between_direction_change = 1
var time_between_direction_change = 1
var timer = 0
var direction_timer = 0
var moving_up = 1

func _process(delta):
	timer += delta
	direction_timer += delta
	if time_between_flicker < timer:
		timer -= time_between_flicker
		flicker()
	if time_between_direction_change < direction_timer:
		if moving_up > 0: moving_up = -1
		else: moving_up = 1
		direction_timer -= time_between_direction_change
		time_between_direction_change = rand_range(min_time_between_direction_change, max_time_between_direction_change)

func flicker():
	light_energy = rand_range(min_energy, max_energy)
	omni_range = max(min_range, min(max_range, omni_range + rand_range(0, 0.1) * moving_up))

