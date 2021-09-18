extends Control

onready var anim = find_node("AnimationPlayer")
onready var SubmenuArrowUp = find_node("SubmenuArrowUp")
onready var SubmenuArrowDown = find_node("SubmenuArrowDown")

func hide():
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
