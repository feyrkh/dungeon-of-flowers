extends BaseMenuItem

export(String) var setting_name = "?"
export(int) var min_value = 0
export(int) var max_value = 100
export(int) var default_value = 100
export(String) var label = "?" setget set_label

onready var Slider:HSlider = find_node("HSlider")

const CLICK_DELAY = 0.2
var click_delay = 0.2
var click_held = 0.0

func _ready():
	$Label.text = label
	Slider.min_value = min_value
	Slider.max_value = max_value
	Slider.value = GameData.get_setting(setting_name, default_value)
	update_value_label(Slider.value)
	set_process(false)

func _process(delta):
	if Input.is_action_pressed("ui_left"):
		adjust_value(-1, delta)
	elif Input.is_action_pressed("ui_right"):
		adjust_value(1, delta)
	elif click_held > 0: 
		click_held = 0.0
		set_process(false)

func menu_increment(menu):
	click_delay = 0.0
	adjust_value(1, 0)
	set_process(true)

func menu_decrement(menu):
	click_delay = 0.0
	adjust_value(-1, 0)
	set_process(true)

func adjust_value(dir, delta):
	click_delay -= delta
	click_held += delta
	if click_delay <= 0:
		AudioPlayerPool.play("res://sound/mixkit-metallic-sword-strike-2160.wav", 5.0)
		click_delay += CLICK_DELAY
		var increment = 1
		if click_held >= 2:
			increment = 10
		elif click_held >= 1:
			increment = 5
		Slider.value = Slider.value + increment * dir

func set_label(val):
	label = val
	$Label.text = label

func update_value_label(new_value):
	$Value.text = str(new_value)
	GameData.update_setting(setting_name, new_value)

func menu_deselected(menu):
	.menu_deselected(menu)
	set_process(false)

func _on_HSlider_value_changed(value):
	update_value_label(value)
