extends TextureRect

const TEXT_FADE_DURATION = 0.125
const TEXT_STAY_DURATION_MIN = 1.0
const TEXT_STAY_DURATION_PER_WORD = 0.25

export(String) var character_prefix = "g:"
var displayed = null setget set_displayed

func _ready():
	modulate.a = 0
	EventBus.connect("chat_msg", self, "chat_msg")
	set_material(get_material().duplicate(true))
	set_dialog_visibility(0)
	set_displayed(null)
	#set_displayed("This is the first", 1)
	#set_displayed("This is the 2nd", 2)
	#set_displayed("This is the 3rd", 3)
	#set_displayed("This is the 4th", 4)
	#set_displayed(null, 5)

func chat_msg(msg):
	if msg == null:
		visible = false
		return
	else:
		visible = true
	if msg.begins_with(character_prefix):
		set_displayed(msg.substr(character_prefix.length()), 0.25)
	else:
		set_displayed(null, 0)

func set_displayed(val, delay=0):
	if val and !displayed:
		show_chat(val, delay)
	elif !val and displayed:
		hide_chat(val, delay)
	elif val and displayed:
		hide_chat(displayed, delay)
		show_chat(val, TEXT_FADE_DURATION+delay)

func show_chat(val, delay=0):
	var tween = Util.one_shot_tween(self)
	displayed = val
	tween.interpolate_property($Label, "modulate:a", 0, 1.0, TEXT_FADE_DURATION, 0, 2, delay+TEXT_FADE_DURATION/2.0)
	tween.interpolate_callback($Label, TEXT_FADE_DURATION+delay, "set_text", val)
	tween.interpolate_method(self, "set_dialog_visibility", 0, 1.0, TEXT_FADE_DURATION, 0, 2, delay)
	tween.start()
	#$Label.text = val

func hide_chat(val, delay=0):
	var tween = Util.one_shot_tween(self)
	displayed = val
	tween.interpolate_property($Label, "modulate:a", 1.0, 0, TEXT_FADE_DURATION/2.0, 0, 2, delay)
	tween.interpolate_method(self, "set_dialog_visibility", 1.0, 0, TEXT_FADE_DURATION, 0, 2, delay)
	tween.start()
	yield(tween, "tween_all_completed")
	$Label.text = ""
	
func set_dialog_visibility(progress):
	material.set_shader_param("progress", progress)

