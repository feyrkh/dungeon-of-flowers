extends OmniLight

export var min_energy = 1.0
export var max_energy = 1.0
export var min_range = 6
export var max_range = 9
export var time_between_flicker = 0.1
var timer = 0

func _process(delta):
	timer += delta
	if time_between_flicker < timer:
		timer -= time_between_flicker
		flicker()

func flicker():
	light_energy = rand_range(min_energy, max_energy)
	omni_range = max(min_range, min(max_range, omni_range + rand_range(-0.1, 0.1)))
