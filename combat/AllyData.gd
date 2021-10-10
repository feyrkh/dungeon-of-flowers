extends Reference
class_name AllyData

var label : String
var className : String
var hp : float setget set_hp
var max_hp : int setget set_max_hp
var sp : float setget set_sp
var max_sp : int setget set_max_sp
var shields = []

var agility = 100 # likely to hit (low damage range increase)
var strength = 100 # likely to penetrate armor (medium damage range increase)
var precision = 100 # likely to get critical hit (high damage range increase)

var texture : String

var moves : Array # of MoveData

func save_data():
	var data = Util.to_config(self)
	return data

func load_data(data:Dictionary):
	Util.config(self, data)

func post_config(c):
	for i in moves.size():
		var move_config = moves[i]
		var move_obj = MoveData.new()
		Util.config(move_obj, move_config)
		moves[i] = move_obj

func round_stats():
	hp = float(int(hp))
	sp = float(int(sp))

func set_hp(val):
	hp = val
	EventBus.emit_signal("ally_status_updated", self)

func set_max_hp(val):
	max_hp = val
	EventBus.emit_signal("ally_status_updated", self)

func set_sp(val):
	sp = val
	EventBus.emit_signal("ally_status_updated", self)

func set_max_sp(val):
	max_sp = val
	EventBus.emit_signal("ally_status_updated", self)

func get_moves(move_type:String):
	var result = []
	for move in moves:
		if move.type == move_type:
			result.append(move)
	return result

func get_shields():
	return shields

func take_damage(amt, type="physical"):
	pass

