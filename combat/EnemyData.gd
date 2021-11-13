extends Reference
class_name EnemyData

var label : String
var hp : int setget set_hp
var max_hp : int
var img : Texture
var intentions = []
var group_count
var dead_followers = 0

var dodge = 100 # decrease total size of low targets
var defend = 100 # decrease size of med targets
var resist = 100 # decrease size of crit targets

func _init(_name:String="???", _max_hp:int=1, _img:Texture=null):
	self.label = _name
	self.max_hp = _max_hp
	self.hp = _max_hp
	self.img = _img

func load_from(data):
	print("Loading enemy from ", data)
	var min_group_count = data.get("min", 1)
	var max_group_count = data.get("max", 1)
	group_count = Util.randi_range(min_group_count, max_group_count+1)
	if group_count < 1: 
		group_count = 1
	data = data.get("enemy")
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
	self.resist = data.resist
	if !self.dodge: self.dodge = 100
	if !self.defend: self.defend = 100
	if !self.resist: self.resist = 100
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
			"bullet_pattern": "slime/dribble"
		}
	else:
		return intentions[rand_range(0, intentions.size())]

func round_stats():
	hp = float(int(hp))

func set_hp(val):
	if hp >= 1 and val < 1:
		CombatMgr.emit_signal("enemy_damage_applied", hp)
		if group_count > 1:
			val = max_hp
		group_count = max(0, group_count-1)
		dead_followers += 1
	elif  hp >= 1 and val < hp:
		CombatMgr.emit_signal("enemy_damage_applied", hp - val)
	hp = val
