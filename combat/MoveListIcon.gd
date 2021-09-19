extends TextureRect

export var skill_type = "attack" # skill, defend, item
var allyData
var moves = []

func setup(_allyData):
	allyData = _allyData
	moves = allyData.get_moves(skill_type)

func is_selectable():
	return moves.size() > 0
