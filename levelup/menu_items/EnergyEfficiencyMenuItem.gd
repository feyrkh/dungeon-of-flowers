extends VBoxContainer

onready var PercentSelector = find_node("PercentSelector")

var existing_meridian
var max_unlocked_efficiency_level

func setup(_existing_meridian, _efficiency_level, _max_unlocked_efficiency_level):
	PercentSelector = find_node("PercentSelector")
	existing_meridian = _existing_meridian
	max_unlocked_efficiency_level = _max_unlocked_efficiency_level
	PercentSelector.setup(efficiency_item_cost_maps(), [], [], _efficiency_level)

func can_highlight():
	return true

func menu_item_highlighted():
	PercentSelector.start_selecting()
	EventBus.emit_signal("grias_component_hide_main_arrow")
	update_text()

func menu_item_unhighlighted():
	update_text()
	PercentSelector.stop_selecting()

func unselected_component_input(event):
	if event.is_action_pressed("ui_left"):
		PercentSelector.select_next(-1)
	elif event.is_action_pressed("ui_right"):
		PercentSelector.select_next(1)
	update_text()

func update_text():
	find_node("DescriptionLabel").text = "Improve energy efficiency"
	var selected_icon = PercentSelector.selected_icon_value()
	var cost = GameData.cost_after_investment(PercentSelector.selected_icon_cost(), {})
	EventBus.emit_signal("grias_component_cost", cost)
	if selected_icon < 0.8:
		EventBus.emit_signal("grias_component_menu_text", "Low efficiency, reducing energy loss through this meridian.")
	elif selected_icon < 1.0:
		EventBus.emit_signal("grias_component_menu_text", "High efficiency, reducing energy loss through this meridian.")
	elif selected_icon == 1.0:
		EventBus.emit_signal("grias_component_menu_text", "Perfect efficiency, eliminating energy loss through this meridian.")
	else:
		EventBus.emit_signal("grias_component_menu_text", "Focusing meridian adds more energy as sparks travel through this meridian.\nExcess energy can disable meridians!")


func component_input_started():
	find_node("DescriptionContainer").modulate = Color.yellow

func component_input_ended():
	find_node("DescriptionContainer").modulate = Color.white

func menu_item_action():
	if PercentSelector.highlighted_icon_is_selected():
		EventBus.emit_signal("grias_component_menu_text", "Already selected!")
		return
	if !PercentSelector.can_select_current():
		EventBus.emit_signal("grias_component_menu_text", "Can't afford!")
		return
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	find_node("DescriptionLabel").text = "Adjust efficiency?  "
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
		var cost = GameData.cost_after_investment(PercentSelector.selected_icon_cost(), {})
		GameData.pay_cost(cost)
		existing_meridian.unlock_efficiency_level(PercentSelector.selected_icon)
		existing_meridian.efficiency_level = PercentSelector.selected_icon
		EventBus.emit_signal("grias_levelup_major_component_upgrade", C.element_color(existing_meridian.element))
		#EventBus.emit_signal("grias_exit_component_mode")

func efficiency_item_cost_maps():
	var costs = [null]
	var cost_map = {}

	if max_unlocked_efficiency_level >= 1: # .9
		costs.append(null)
	else:
		Util.inc(cost_map, C.ELEMENT_SOIL, 1)
		costs.append(cost_map.duplicate())

	if max_unlocked_efficiency_level >= 2: # 1.0
		costs.append(null)
	else:
		Util.inc(cost_map, C.ELEMENT_WATER, 1)
		costs.append(cost_map.duplicate())

	if max_unlocked_efficiency_level >= 3: # 1.1
		costs.append(null)
	else:
		Util.inc(cost_map, C.ELEMENT_SUN, 2)
		costs.append(cost_map.duplicate())

	return costs
