extends Reference
class_name AllyData

var label : String
var className : String
var hp : int
var max_hp : int
var sp : int
var max_sp : int
var balance : int
var max_balance : int

var stance_height : int
var stance_sidestep : int
var stance_angle : int

var texture : Texture

var moves : Array # of MoveData

func get_moves(move_type:String):
	var result = []
	for move in moves:
		if move.type == move_type:
			result.append(move)
	return result
