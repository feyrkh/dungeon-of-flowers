extends Reference
class_name EnemyData

var label : String
var hp : int
var max_hp : int
var img : Texture
var weakspot_offsets : Array

func _init(name:String, max_hp:int, img:Texture, weakspot_offsets:Array):
	self.label = name
	self.max_hp = max_hp
	self.hp = max_hp
	self.weakspot_offsets = weakspot_offsets
	self.img = img
