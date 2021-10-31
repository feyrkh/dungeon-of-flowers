extends Node2D

signal timer_complete()

export(bool) var started = false
export(bool) var auto_restart = false
export(float) var timer_length = 10.0
export(float) var pixel_length = 500
var cur_timer
var max_scale_x = 1

func _ready():
	max_scale_x = pixel_length / $ColorRect.rect_size.x
	cur_timer = timer_length

func reset_timer(t=timer_length):
	timer_length = t
	cur_timer = t

func update_timer(delta):
	if cur_timer > 0:
		cur_timer -= delta
		if cur_timer <= 0:
			cur_timer = 0
			emit_signal("timer_complete")
			if auto_restart:
				reset_timer()
		$ColorRect.rect_scale.x = max_scale_x * (cur_timer/timer_length)
