extends Node2D
class_name Enemy

const Weakspot = preload("res://combat/Weakspot.tscn")
const DamageFloater = preload("res://combat/DamageFloater.tscn")

const INTENTION_ATTACK_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_fight.png"
const INTENTION_DEFEND_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_defend.png"
const INTENTION_UNKNOWN_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_item.png"

signal target_button_pressed
signal target_button_entered
signal target_button_exited

onready var sprite = find_node('Sprite')
onready var IntentionIcon = find_node("IntentionIcon")

var data : EnemyData
var intention

func setup(_data:EnemyData):
	self.data = _data

func is_alive():
	return data.hp > 0

func damage_hp(amt):
	self.data.hp -= amt
	print(data.label + " has "+str(data.hp)+" hp left")
	var floater = DamageFloater.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	floater.set_damage(round(amt))
	add_child(floater)
	if amt > 0:
		Util.shake(self, 0.2, 20, self, "check_death")

func decide_enemy_action():
	intention = data.get_next_intention()
	var intention_texture = INTENTION_UNKNOWN_IMG
	match intention.get("type"):
		"attack": 
			intention_texture = INTENTION_ATTACK_IMG
		"defend": 
			intention_texture = INTENTION_DEFEND_IMG
	IntentionIcon.visible = true
	IntentionIcon.texture = load(intention_texture)

func check_death():
	if self.data.hp <= 0:
		die()

func die():
	CombatMgr.emit_signal("enemy_dead", self)
	queue_free()

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


