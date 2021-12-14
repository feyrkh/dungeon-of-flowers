extends Control

#onready var DescriptionLabel = find_node("DescriptionLabel", true, false)

var element = 0
var cost = 1
var prefix = "Awaken"
var already_unlocked

func _ready():
	pass

func can_highlight():
	return true

func can_menu_item_action():
	return GameData.can_afford({element:cost})

func setup(_element, _prefix, elements_unlocked):
	element = _element
	prefix = _prefix
	already_unlocked = elements_unlocked.find(_element) >= 0
	if already_unlocked:
		cost = 0
	else:
		cost = pow(3, elements_unlocked.size())
	if GameData.get_state("grias_levelup_energy")[element] < cost and !already_unlocked:
		modulate = Color.dimgray
	if element == C.ELEMENT_DECAY and modulate != Color.white:
		queue_free()
	update_text()

func update_text():
	$VBoxContainer/DescriptionLabel.text = prefix+" "+C.element_name(element).capitalize()+" Core"

func menu_item_highlighted():
	if already_unlocked:
		EventBus.emit_signal("grias_component_cost", {})
	else:
		EventBus.emit_signal("grias_component_cost", {element:cost})
	EventBus.emit_signal("grias_component_menu_text", "Use "+C.element_name(element)+" pollen to awaken this core.")

func menu_item_action():
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	if already_unlocked:
		$VBoxContainer/DescriptionLabel.text = "Already unlocked - reawaken?  "
	else:
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
		EventBus.emit_signal("grias_levelup_major_component_upgrade", C.element_color(element))
