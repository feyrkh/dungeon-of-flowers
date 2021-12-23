extends MarginContainer

const COSTS = {
	C.ELEMENT_SOIL: 3,
	C.ELEMENT_WATER: 3,
	C.ELEMENT_SUN: 3,
}

func _ready():
	find_node("ConfirmDialog").visible = false

func can_highlight():
	return true

func menu_item_highlighted():
	update_text()

func menu_item_unhighlighted():
	update_text()

func update_text():
	EventBus.emit_signal("grias_component_cost", COSTS)
	if !GameData.can_afford(COSTS):
		EventBus.emit_signal("grias_component_menu_text", "Can't afford!")
		return
	EventBus.emit_signal("grias_component_menu_text", "Allow more energy to be focused into the node it is facing, increasing the effectiveness of a powered nexus.")

func component_input_started():
	find_node("DescriptionContainer").modulate = Color.yellow

func component_input_ended():
	find_node("DescriptionContainer").modulate = Color.white

func menu_item_action():
	if !GameData.can_afford(COSTS):
		return
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	find_node("DescriptionLabel").text = "Empower focus node?  "
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
		EventBus.emit_signal("grias_component_change", "build_focus", COSTS, null)
		EventBus.emit_signal("grias_levelup_major_component_upgrade", Color.white)
