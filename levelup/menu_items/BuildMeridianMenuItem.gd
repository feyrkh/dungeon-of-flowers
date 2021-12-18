extends MarginContainer

const COSTS = {
	C.ELEMENT_SOIL: {C.ELEMENT_SOIL: 1},
	C.ELEMENT_WATER: {C.ELEMENT_WATER: 1},
	C.ELEMENT_SUN: {C.ELEMENT_SUN: 1},
	C.ELEMENT_DECAY: {C.ELEMENT_DECAY: 1},
	C.ELEMENT_ALL: {C.ELEMENT_SOIL:1, C.ELEMENT_WATER:1, C.ELEMENT_SUN:1},
}

var element = C.ELEMENT_ALL
var cost = {C.ELEMENT_SOIL:1, C.ELEMENT_WATER:1, C.ELEMENT_SUN:1}
var existing_meridian
var investment = {}

onready var EnergySelector = find_node("EnergySelector")

func _ready():
	var highlighted_element = -1
	if existing_meridian:
		highlighted_element = existing_meridian.element
	EnergySelector.setup(true, 1, investment, highlighted_element)
	find_node("ConfirmDialog").visible = false

func upgrade(_existing_meridian):
	existing_meridian = _existing_meridian
	investment = existing_meridian.investment

func can_highlight():
	return true

func menu_item_highlighted():
	EnergySelector.start_selecting()
	EventBus.emit_signal("grias_component_hide_main_arrow")
	update_text()

func menu_item_unhighlighted():
	update_text()
	EnergySelector.stop_selecting()

func unselected_component_input(event):
	if event.is_action_pressed("ui_left"):
		EnergySelector.select_next(-1)
	elif event.is_action_pressed("ui_right"):
		EnergySelector.select_next(1)
	element = EnergySelector.selected_element_id()
	cost = GameData.cost_after_investment(COSTS[element], investment)
	update_text()

func update_text():
	element = EnergySelector.selected_element_id()
	cost = GameData.cost_after_investment(COSTS[element], investment)
	EventBus.emit_signal("grias_component_cost", cost)
	EventBus.emit_signal("grias_component_menu_text", "Conserve and redirect "+C.element_name(element)+" energy")

func component_input_started():
	find_node("DescriptionContainer").modulate = Color.yellow

func component_input_ended():
	find_node("DescriptionContainer").modulate = Color.white

func menu_item_action():
	if EnergySelector.highlighted_icon_is_selected():
		EventBus.emit_signal("grias_component_menu_text", "Already selected!")
		return
	if !EnergySelector.can_select_current():
		EventBus.emit_signal("grias_component_menu_text", "Can't afford!")
		return
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	find_node("DescriptionLabel").text = "Empower meridian for "+C.element_name(element)+" energy?  "
	find_node("ConfirmDialog").visible = true
	find_node("ConfirmDialog").cur_choice = false

func component_input(event):
	if event.is_action("ui_left") and !event.is_action_released("ui_left") or event.is_action("ui_right") and !event.is_action_released("ui_right"):
		find_node("ConfirmDialog").toggle_choice()
	elif event.is_action("ui_cancel") and !event.is_action_released("ui_cancel"):
		choice_made(false)
	elif event.is_action("ui_accept") and !event.is_action_released("ui_accept"):
		choice_made(find_node("ConfirmDialog").cur_choice)

func choice_made(was_yes):
	update_text()
	find_node("ConfirmDialog").visible = false
	EventBus.emit_signal("grias_levelup_component_input_release")
	if was_yes:
		if !existing_meridian:
			EventBus.emit_signal("grias_component_change", "build_meridian", cost, element)
			EventBus.emit_signal("grias_levelup_major_component_upgrade", C.element_color(element))
		else:
			GameData.pay_cost(cost)
			existing_meridian.unlock_element(element, cost)
			EventBus.emit_signal("grias_levelup_major_component_upgrade", C.element_color(element))
			#EventBus.emit_signal("grias_exit_component_mode")
