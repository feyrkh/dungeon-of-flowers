extends Control

#onready var DescriptionLabel = find_node("DescriptionLabel", true, false)

var element = 0
var cost = 1
var prefix = "Awaken"

func _ready():
	if GameData.get_state("grias_levelup_energy")[element] < cost:
		queue_free()

func can_highlight():
	return true

func setup(_element, _prefix):
	element = _element
	prefix = _prefix
	update_text()

func update_text():
	$VBoxContainer/DescriptionLabel.text = prefix+" "+C.element_name(element).capitalize()+" Core"

func menu_item_highlighted():
	EventBus.emit_signal("grias_component_text", "Use the power of "+C.element_name(element)+" pollen to awaken this core.")

func menu_item_action():
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	$VBoxContainer/DescriptionLabel.text = "Awaken for "+str(cost)+" "+C.element_name(element)+"?  "
	find_node("ConfirmDialog").visible = true
	find_node("ConfirmDialog").cur_choice = false

func component_input_started():
	self.modulate = Color.yellow

func component_input_ended():
	self.modulate = Color.white

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
		EventBus.emit_signal("grias_component_change", "awaken_core", {element: cost}, element)
