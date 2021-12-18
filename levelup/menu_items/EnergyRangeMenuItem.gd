extends VBoxContainer

onready var RangeSelector = find_node("RangeSelector")

var existing_meridian
var max_unlocked_range_level

func setup(_existing_meridian, _range_level, _max_unlocked_range_level):
	RangeSelector = find_node("RangeSelector")
	existing_meridian = _existing_meridian
	max_unlocked_range_level = _max_unlocked_range_level
	RangeSelector.setup(range_item_cost_maps(), [], [], _range_level)

func can_highlight():
	return true

func menu_item_highlighted():
	RangeSelector.start_selecting()
	EventBus.emit_signal("grias_component_hide_main_arrow")
	update_text()

func menu_item_unhighlighted():
	update_text()
	RangeSelector.stop_selecting()

func unselected_component_input(event):
	if event.is_action_pressed("ui_left"):
		RangeSelector.select_next(-1)
	elif event.is_action_pressed("ui_right"):
		RangeSelector.select_next(1)
	update_text()

func update_text():
	find_node("DescriptionLabel").text = "Improve tunneling distance"
	var selected_icon = RangeSelector.selected_icon_value()
	var cost = GameData.cost_after_investment(RangeSelector.selected_icon_cost(), {})
	EventBus.emit_signal("grias_component_cost", cost)
	if selected_icon == 0:
		EventBus.emit_signal("grias_component_menu_text", "Energy passing through will move normally.")
	else:
		EventBus.emit_signal("grias_component_menu_text", "Energy passing through will swiftly travel "+str(RangeSelector.selected_icon_value())+" tiles without interacting with anything, but can not emerge into disordered tiles.")


func component_input_started():
	find_node("DescriptionContainer").modulate = Color.yellow

func component_input_ended():
	find_node("DescriptionContainer").modulate = Color.white

func menu_item_action():
	if RangeSelector.highlighted_icon_is_selected():
		EventBus.emit_signal("grias_component_menu_text", "Already selected!")
		return
	if !RangeSelector.can_select_current():
		EventBus.emit_signal("grias_component_menu_text", "Can't afford!")
		return
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	find_node("DescriptionLabel").text = "Adjust tunneling?  "
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
		var cost = GameData.cost_after_investment(RangeSelector.selected_icon_cost(), {})
		GameData.pay_cost(cost)
		existing_meridian.unlock_range_level(RangeSelector.selected_icon)
		existing_meridian.range_level = RangeSelector.selected_icon_value()
		EventBus.emit_signal("grias_levelup_major_component_upgrade", C.element_color(existing_meridian.element))
		#EventBus.emit_signal("grias_exit_component_mode")

func range_item_cost_maps():
	var costs = [null]
	var cost_map = {}

	for i in range(4):
		if max_unlocked_range_level >= i+1:
			costs.append(null)
		else:
			Util.inc(cost_map, C.ELEMENT_SUN, 1)
			costs.append(cost_map.duplicate())

	return costs
