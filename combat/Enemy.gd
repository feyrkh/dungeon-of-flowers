extends Node2D
class_name Enemy

const Weakspot = preload("res://combat/Weakspot.tscn")
const DamageFloater = preload("res://combat/DamageFloater.tscn")

onready var sprite = find_node('Sprite')
onready var IntentionIcon = find_node("IntentionIcon")

var data : EnemyData
var intention


func _ready():
	if !data:
		data = EnemyData.new("Furry Guy", 30, preload("res://img/monster1.jpg"))
	sprite.texture = data.img
	$DamageIndicator.connect("all_damage_applied", self, "_on_all_damage_applied")

func setup(_data:EnemyData):
	self.data = _data

func is_alive():
	return data.hp > 0

func damage_hp(amt):
	# TODO: accumulate damage here instead of doing direct damage
	#self.data.hp -= amt
	#print(data.label + " has "+str(data.hp)+" hp left")
	$DamageIndicator.take_damage(amt)
	var floater = DamageFloater.instance()
	floater.set_damage(round(amt))
	add_child(floater)

func _on_all_damage_applied(amt):
	if amt > 0:
		Util.shake(self, 0.2, 20, self, "check_death")
		
func apply_damage():
	$DamageIndicator.apply_damage(data)

func decide_enemy_action():
	intention = data.get_next_intention()
	IntentionIcon.setup(self, intention)

func check_death():
	if self.data.hp <= 0:
		die()

func die():
	CombatMgr.emit_signal("enemy_dead", self)
	queue_free()
	
func highlight():
	find_node("Pulser").start()

func unhighlight():
	find_node("Pulser").stop()


