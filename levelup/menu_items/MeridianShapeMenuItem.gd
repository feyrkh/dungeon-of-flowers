extends MarginContainer

onready var MeridianShapeSelector = find_node("MeridianShapeSelector")

var existing_meridian

func setup(_existing_meridian, _unlocked_directions):
	existing_meridian = _existing_meridian
	find_node("MeridianShapeSelector").setup([
		{}, {C.ELEMENT_SOIL:1}, {C.ELEMENT_SOIL:1}, {C.ELEMENT_WATER:1}, {C.ELEMENT_WATER:1}, {C.ELEMENT_SUN:1}
	], [existing_meridian.direction], _unlocked_directions, existing_meridian.direction)

func can_highlight():
	return true

func menu_item_highlighted():
	MeridianShapeSelector.start_selecting()
	EventBus.emit_signal("grias_component_hide_main_arrow")
	update_text()

func menu_item_unhighlighted():
	update_text()
	MeridianShapeSelector.stop_selecting()

func unselected_component_input(event):
	if event.is_action_pressed("ui_left"):
		MeridianShapeSelector.select_next(-1)
	elif event.is_action_pressed("ui_right"):
		MeridianShapeSelector.select_next(1)
	update_text()

func update_text():
	var selected_icon = MeridianShapeSelector.selected_icon_value()
	var cost = GameData.cost_after_investment(MeridianShapeSelector.selected_icon_cost(), {})
	EventBus.emit_signal("grias_component_cost", cost)
	EventBus.emit_signal("grias_component_menu_text", "Reshape as a "+C.meridian_dir_name(selected_icon)+" meridian")

func component_input_started():
	find_node("DescriptionContainer").modulate = Color.yellow

func component_input_ended():
	find_node("DescriptionContainer").modulate = Color.white

func menu_item_action():
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	find_node("DescriptionLabel").text = "Reshape meridian?  "
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
		var cost = GameData.cost_after_investment(MeridianShapeSelector.selected_icon_cost(), {})
		GameData.pay_cost(cost)
		existing_meridian.unlock_direction(MeridianShapeSelector.selected_icon_value())
		existing_meridian.direction = MeridianShapeSelector.selected_icon_value()
		EventBus.emit_signal("grias_levelup_major_component_upgrade", C.element_color(existing_meridian.element))
		EventBus.emit_signal("grias_exit_component_mode")
