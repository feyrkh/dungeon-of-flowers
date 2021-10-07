extends Reference
class_name EnemyData

var label : String
var hp : int
var max_hp : int
var img : Texture
var intentions = []

var dodge = 100 # decrease total size of low targets
var defend = 100 # decrease size of med targets
var parry = 100 # decrease size of crit targets

func _init(_name:String="???", _max_hp:int=10, _img:Texture=null):
	self.label = _name
	self.max_hp = _max_hp
	self.hp = _max_hp
	self.img = _img

func load_from(data):
	if data is Array: # pick a random enemy from the options if this is an array
		data = data[rand_range(0, data.size())] 
	if data is String: # load the enemy data from a file if this is a string
		data = DialogicResources.load_json("res://data/enemy/"+data+".json")
	self.label = data.label
	self.hp = data.hp
	self.max_hp = data.hp
	self.img = load(data.img)
	self.intentions = data.intentions
	self.dodge = data.dodge
	self.defend = data.defend
	self.parry = data.parry
	if !self.dodge: self.dodge = 100
	if !self.defend: self.defend = 100
	if !self.parry: self.parry = 100
	if !self.intentions:
		self.intentions = []
	for i in range(self.intentions.size()):
		if intentions[i] is String:
			var intention_name = intentions[i]
			intentions[i] = DialogicResources.load_json("res://data/intention/"+intention_name+".json")
			intentions[i]["name"] = intention_name
			

func get_next_intention():
	if !intentions or intentions.size() == 0:
		return {
			"name": "unknown_attack",
			"type": "attack",
			"base_damage": 0.5,
			"attacks": 2,
			"attacks_per_pulse": 2,
			"target_scatter": 1,
			"target_change_chance": 1,
			"origin_scatter": 0,
			"origin_change_chance": 0,
		}
	else:
		return intentions[rand_range(0, intentions.size())]
