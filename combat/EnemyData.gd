extends Reference
class_name EnemyData

const HP_MULTIPLIER_PER_THREAT_LEVEL = 0.1
const DODGE_MULTIPLIER_PER_THREAT_LEVEL = 0.1
const DEFEND_MULTIPLIER_PER_THREAT_LEVEL = 0.1
const RESIST_MULTIPLIER_PER_THREAT_LEVEL = 0.1

var label : String
var hp = load("res://util/StatValue.gd").new()
var img : Texture
var intentions = []
var group_count
var dead_followers = 0

var dodge = 100 # decrease total size of low targets
var defend = 100 # decrease size of med targets
var resist = 100 # decrease size of crit targets

func _init(_name:String="???", _max_hp:int=1, _img:Texture=null):
	self.label = _name
	self.hp.max_value = _max_hp
	self.hp.value = _max_hp
	self.img = _img
	hp.connect("value_changed", self, "on_set_hp")

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
	self.hp.value = data.hp * (1+GameData.get_threat_level()*HP_MULTIPLIER_PER_THREAT_LEVEL)
	self.hp.max_value = data.hp * (1+GameData.get_threat_level()*HP_MULTIPLIER_PER_THREAT_LEVEL)
	self.img = load(data.img)
	self.intentions = data.intentions
	self.dodge = data.dodge * (1+GameData.get_threat_level()*DODGE_MULTIPLIER_PER_THREAT_LEVEL)
	self.defend = data.defend * (1+GameData.get_threat_level()*DEFEND_MULTIPLIER_PER_THREAT_LEVEL)
	self.resist = data.resist * (1+GameData.get_threat_level()*RESIST_MULTIPLIER_PER_THREAT_LEVEL)
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
	hp.value = float(int(hp.value))

func on_set_hp(old_val, val):
	if old_val >= 1 and val < 1:
		CombatMgr.emit_signal("enemy_damage_applied", old_val)
		if group_count > 1:
			hp.set_value(hp.max_value, true)
		group_count = max(0, group_count-1)
		dead_followers += 1
	elif hp.value >= 1 and val < old_val:
		CombatMgr.emit_signal("enemy_damage_applied", old_val - val)
