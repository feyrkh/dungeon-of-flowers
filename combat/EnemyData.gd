extends Reference
class_name EnemyData

var label : String
var hp : int
var max_hp : int
var img : Texture
var weakspot_offsets : Array

func _init(_name:String, _max_hp:int, _img:Texture, _weakspot_offsets:Array):
	self.label = _name
	self.max_hp = _max_hp
	self.hp = _max_hp
	self.weakspot_offsets = weakspot_offsets
	self.img = _img

func get_next_intention():
	return {
		"type": "attack",
		"base_damage": 0.5,
		"attacks": 10,
		"attacks_per_pulse": 2,
		"target_scatter": 1,
		"target_change_chance": 1,
		"origin_scatter": 0,
		"origin_change_chance": 0,
	}
