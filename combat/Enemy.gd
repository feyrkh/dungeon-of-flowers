extends Node2D
class_name Enemy

const Weakspot = preload("res://combat/Weakspot.tscn")
const DamageFloater = preload("res://combat/DamageFloater.tscn")

signal target_button_pressed
signal target_button_entered
signal target_button_exited

onready var sprite = find_node('Sprite')
var data : EnemyData

func setup(_data:EnemyData):
	self.data = _data

func damage_hp(amt):
	self.data.hp -= amt
	print(data.label + " has "+str(data.hp)+" hp left")
	var floater = DamageFloater.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	floater.set_damage(round(amt))
	add_child(floater)
	if amt > 0:
		Util.shake(self, 0.2, 20)
		yield(get_tree().create_timer(0.5), "timeout")
		
		

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
