extends Reference
class_name AllyData

var label : String
var className : String
var hp : int
var max_hp : int
var sp : int
var max_sp : int
var shields = []

var texture : Texture

var moves : Array # of MoveData

func get_moves(move_type:String):
	var result = []
	for move in moves:
		if move.type == move_type:
			result.append(move)
	return result

func get_shields():
	return shields

func take_damage(amt, type="physical"):
	hp -= amt
	CombatMgr.emit_signal("attack_bullet_strike", self)
