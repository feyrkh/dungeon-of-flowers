extends Node2D
class_name Enemy

const Weakspot = preload("res://combat/Weakspot.tscn")

signal target_button_pressed
signal target_button_entered
signal target_button_exited

onready var sprite = find_node('Sprite')
var data : EnemyData

func setup(data:EnemyData):
	self.data = data

func _ready():
	if !data:
		data = EnemyData.new("Furry Guy", 30, preload("res://img/monster1.jpg"), [])
	sprite.texture = data.img

func highlight():
	find_node("Pulser").start()

func unhighlight():
	find_node("Pulser").stop()

func _on_TargetButton_pressed():
	print("Targeted an enemy: "+data.label)
	emit_signal("target_button_hover")


func _on_Area2D_mouse_entered():
	print("Mouse entered enemy: "+data.label)
	emit_signal("target_button_entered")


func _on_Area2D_mouse_exited():
	print("Mouse left enemy: "+data.label)
	emit_signal("target_button_exited")


func _on_Area2D_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton && event.pressed):
		emit_signal("target_button_pressed")
