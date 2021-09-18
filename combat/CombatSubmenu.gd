extends Control

signal cancel_submenu
signal select_submenu_item(item_idx)

onready var anim = find_node("AnimationPlayer")
onready var SubmenuArrowUp = find_node("SubmenuArrowUp")
onready var SubmenuArrowDown = find_node("SubmenuArrowDown")

func _ready():
	set_process(false)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		hide()
		yield(anim, "animation_finished")
		emit_signal("cancel_submenu")

func hide():
	set_process(false)
	SubmenuArrowUp.visible = false
	SubmenuArrowDown.visible = false
	anim.play("fade")
	yield(anim, "animation_finished")
	self.visible = false

func show():
	self.visible = true
	anim.play_backwards("fade")
	yield(anim, "animation_finished")
	SubmenuArrowUp.visible = true
	SubmenuArrowDown.visible = true
	set_process(true)
