extends Node

func _ready() -> void:
	EventBus.connect("screen_flash", self, "screen_flash")

func screen_flash(t:float, c:Color):
	var flash = preload("res://util/ScreenFlash.tscn").instance()
	add_child(flash)
	flash.flash(t, c)

