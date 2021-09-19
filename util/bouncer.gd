extends Control

export(Vector2) var bounce_vector
export(float) var bounce_time = 2
export(Curve) var ease_curve
export(bool) var running = true
onready var start_position = rect_position

var counter = 0

func _process(delta):
	if !running: 
		counter = 0
	else:
		counter += delta
	if counter > bounce_time: 
		counter -= bounce_time
	var weight = counter/bounce_time
	weight = ease_curve.interpolate_baked(weight)
	rect_position = lerp(start_position, start_position + bounce_vector, weight)

func reset():
	counter = 0
