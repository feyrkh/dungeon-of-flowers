extends MarginContainer

export(float) var delay = 1.5
export(bool) var pause_after_delay = true
export(String) var delayed_tutorial

func _ready():
	set_process(false)

func show_tutorial():
	set_process(true)

func _process(delta):
	if delay > 0:
		delay -= delta
	if delay <= 0:
		set_process(false)
		EventBus.emit_signal("show_tutorial", delayed_tutorial, pause_after_delay)
