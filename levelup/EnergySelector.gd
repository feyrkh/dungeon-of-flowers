extends Container

const ELEMENT_ORDER = [C.ELEMENT_ALL, C.ELEMENT_SOIL, C.ELEMENT_WATER, C.ELEMENT_SUN, C.ELEMENT_DECAY]

onready var ComponentMenuArrow = find_node("ComponentMenuArrow")

var selected_element = 0 # element the cursor is over
var highlighted_element = -1 # element that was previously chosen and is currently highlighted
var investment = {}
var disabled_elements = []

func _ready():
	pass

func setup(has_all, cost=1, _investment={}, _highlighted_element_value=-1):
	investment = _investment
	highlighted_element = ELEMENT_ORDER.find(_highlighted_element_value)
	selected_element = highlighted_element
	if !GameData.can_afford({C.ELEMENT_DECAY:1}):
		disabled_elements.append(ELEMENT_ORDER.find(C.ELEMENT_DECAY))
	for element_id in C.ELEMENT_IDS:
		update_options({element_id:cost}, element_id)
	if has_all:
		update_options({C.ELEMENT_SOIL:cost, C.ELEMENT_SUN:cost, C.ELEMENT_WATER:cost}, C.ELEMENT_ALL)
		find_node("AllIcon").visible = true
	else:
		find_node("AllIcon").visible = false

func update_options(_cost_map, element_id):
	var cost_map = GameData.cost_after_investment(_cost_map, investment)
	var element_name = C.element_name(element_id).capitalize()
	if !GameData.can_afford(cost_map):
		find_node(element_name+"Icon").modulate = Color.dimgray
		find_node(element_name+"Icon").find_node("whirl").visible = false
		if element_id == C.ELEMENT_DECAY:
			find_node(element_name+"Icon").visible = false
	elif highlighted_element == ELEMENT_ORDER.find(element_id):
		find_node(element_name+"Icon").modulate = Color(1, 1, 0.99)
		find_node(element_name+"Icon").find_node("whirl").visible = true
	else:
		find_node(element_name+"Icon").modulate = Color.white
		find_node(element_name+"Icon").find_node("whirl").visible = false
		if element_id == C.ELEMENT_DECAY:
			find_node(element_name+"Icon").visible = true

func start_selecting():
	ComponentMenuArrow.visible = true
	selected_element = highlighted_element
	select_next(0)

func stop_selecting():
	ComponentMenuArrow.visible = false

func selected_element_id():
	if selected_element == -1:
		return -1
	return ELEMENT_ORDER[selected_element]

func selected_element_node():
	if selected_element < 0:
		return null
	var element_name = C.element_name(selected_element_id()).capitalize()
	return find_node(element_name+"Icon")

func can_select_current():
	return selected_element_node().modulate == Color.white

func highlighted_icon_is_selected():
	return selected_element == highlighted_element

func update_arrow_pos():
	var element_name = C.element_name(selected_element_id()).capitalize()
	var selected_node = find_node(C.element_name(selected_element_id()).capitalize()+"Icon")
	var target_item = selected_element_node()
	var target_position = target_item.rect_global_position
	ComponentMenuArrow.rect_global_position = target_position - Vector2(ComponentMenuArrow.rect_size.x, -8)

func select_next(dir=1):
	if dir == 0 and selected_element == -1:
		selected_element = 0
	#selected_element = Util.wrap_range(selected_element+dir, ELEMENT_ORDER.size())
	for i in range(ELEMENT_ORDER.size()):
		selected_element = Util.wrap_range(selected_element+dir, ELEMENT_ORDER.size())
		if !disabled_elements.has(selected_element):
			break
	if disabled_elements.has(selected_element):
		# no selectable elements
		selected_element = -1
		stop_selecting()
	update_arrow_pos()
