extends MarginContainer

onready var FacingSelector = find_node("FacingSelector")

var existing_component

func setup(_existing_component):
	existing_component = _existing_component
	find_node("FacingSelector").setup(null, null, null, existing_component.facing)

func can_highlight():
	return true

func menu_item_highlighted():
	FacingSelector.start_selecting()
	EventBus.emit_signal("grias_component_hide_main_arrow")
	update_text()

func menu_item_unhighlighted():
	update_text()
	FacingSelector.stop_selecting()

func unselected_component_input(event):
	if event.is_action_pressed("ui_left"):
		FacingSelector.select_next(-1)
	elif event.is_action_pressed("ui_right"):
		FacingSelector.select_next(1)
	update_text()

func update_text():
	var rotation = FacingSelector.selected_icon_value()
	existing_component.facing = rotation
	existing_component.render_component()
	find_node("FacingSelector").setup(null, null, null, existing_component.facing)
	EventBus.emit_signal("grias_component_cost", null)
	EventBus.emit_signal("grias_component_menu_text", "Rotate the meridian")
