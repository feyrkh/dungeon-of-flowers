extends TextureButton

const selected_color = Color.white
const deselected_color = Color(0.6, 0.6, 0.6)

var allyData
var default_y

func _ready():
	default_y = rect_position.y

func setup(_allyData):
	allyData = _allyData

func is_selectable():
	return true

func unhighlight():
	modulate = deselected_color
	get_node("Label").visible = false
	rect_position.y = default_y
#	if i < category_ys.size():
#		categories[i].rect_position.y = category_ys[i]

func highlight():
	modulate = selected_color
	get_node("Label").visible = true
	rect_position.y = default_y - 10
#	if i < category_ys.size():
#		categories[i].rect_position.y = category_ys[i] - 10
