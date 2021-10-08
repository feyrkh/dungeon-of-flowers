extends PanelContainer
class_name TutorialTipResume

onready var FillBar = find_node("FillBar")
var fill_amt = 0
export(float) var seconds_to_fill = 1.5

func _ready():
	FillBar.visible = true
	update_fill_bar()
	set_process(false)

func start():
	fill_amt = 0
	update_fill_bar()
	set_process(true)

func _process(delta):
	if fill_amt < 1.0:
		fill_amt += min(1.0, delta/seconds_to_fill)
		update_fill_bar()
		if fill_amt >= 1.0:
			FillBar.visible = false
			$Label.modulate.a = 1
			$Pulser.enabled = true
	else:
		if Input.is_action_just_pressed("ui_accept"):
			EventBus.emit_signal("hide_tutorial")
			self.queue_free()

func update_fill_bar():
	FillBar.rect_scale.x = fill_amt
