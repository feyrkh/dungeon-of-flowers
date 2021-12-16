tool
extends Container
class_name IconSelector

onready var ComponentMenuArrow = find_node("ComponentMenuArrow")

var selected_icon = 0
var unlocked_icons = []
var disabled_icons = []
export(Array, int) var icon_values = []
export(Array, Dictionary) var cost_maps = []

onready var Selections = find_node("Selections", true, false)

func _get_configuration_warning():
	var child_size = Selections.get_child_count()
	if child_size != icon_values.size():
		return "Incorrect number of icon_values, expected "+str(child_size)
	if child_size != cost_maps.size():
		return "Incorrect number of cost_maps, expected "+str(child_size)
	if !find_node("ComponentMenuArrow", true, false):
		return "Expected to find arrow node named 'ComponentMenuArrow'"
	return ""

func _ready():
	pass

func setup(_cost_maps=[], _disabled_icons=[], _unlocked_icons=[], cur_selected_value=-1):
	Selections = find_node("Selections")
	cost_maps = _cost_maps.duplicate()
	disabled_icons = _disabled_icons
	unlocked_icons = _unlocked_icons
	for icon in unlocked_icons:
		cost_maps[icon] = null
	for icon_id in range(Selections.get_child_count()):
		update_options(cost_maps[icon_id], icon_id, icon_values[icon_id]==cur_selected_value)

func update_options(cost_map, icon_id, is_selected):
	var icon_node = Selections.get_child(icon_id)
	if is_selected:
		icon_node.modulate = Color.aquamarine
	elif (!unlocked_icons.has(icon_values[icon_id]) and !GameData.can_afford(cost_map)) or disabled_icons.has(icon_id):
		icon_node.modulate = Color.dimgray
	else:
		icon_node.modulate = Color.white

func start_selecting():
	ComponentMenuArrow.visible = true
	selected_icon = -1
	select_next(1)

func stop_selecting():
	ComponentMenuArrow.visible = false

func selected_icon_node():
	if selected_icon < 0:
		return null
	return Selections.get_child(selected_icon)

func selected_icon_value():
	if selected_icon < 0:
		return null
	return icon_values[selected_icon]

func selected_icon_cost():
	if selected_icon < 0:
		return null
	return cost_maps[selected_icon]

func update_arrow_pos():
	var target_item = selected_icon_node()
	var target_position = target_item.rect_global_position
	ComponentMenuArrow.rect_global_position = target_position - Vector2(ComponentMenuArrow.rect_size.x, -8)

func select_next(dir=1):
	var child_count = Selections.get_child_count()
	for i in range(child_count):
		selected_icon = Util.wrap_range(selected_icon+dir, child_count)
		if selected_icon_node().modulate == Color.white:
			break
	if !selected_icon_node().modulate == Color.white:
		# no selectable elements
		selected_icon = -1
		stop_selecting()
	update_arrow_pos()
