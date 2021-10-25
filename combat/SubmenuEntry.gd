extends TextureRect

onready var label = find_node("Label")

var move_data

func setup(_move_data):
	self.move_data = _move_data
	if !is_disabled():
		label.text = move_data.label
		self.modulate = Color.white
	else:
		label.text = ""
		if move_data:
			label.text = move_data.label
		self.modulate = Color(0.3, 0.3, 0.3)

func is_disabled():
	return move_data == null or move_data.disabled

func is_selectable():
	return !is_disabled()
