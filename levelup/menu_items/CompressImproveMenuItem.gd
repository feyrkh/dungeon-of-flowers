extends MarginContainer

var node
var refund = {}
var map_coords
var tilemap_mgr

func _ready():
	find_node("ConfirmDialog").visible = false

func setup(_node):
	self.node = _node
	update_text()

func can_highlight():
	return true

func menu_item_highlighted():
	update_text()

func menu_item_unhighlighted():
	EventBus.emit_signal("grias_component_refund", null)

func update_text():
	if !GameData.can_afford(get_upgrade_cost()):
		modulate = Color.dimgray
	EventBus.emit_signal("grias_component_cost", get_upgrade_cost())
	EventBus.emit_signal("grias_component_menu_text", "Increase max compression to %.2f" % [node.threshold_upgrades * 0.25 + 1.25])

func component_input_started():
	find_node("DescriptionContainer").modulate = Color.yellow

func component_input_ended():
	find_node("DescriptionContainer").modulate = Color.white

func can_menu_item_action():
	return GameData.can_afford(get_upgrade_cost())

func menu_item_action():
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	find_node("DescriptionLabel").text = "Increase max compression to %.2f?  " % [node.threshold_upgrades * 0.25 + 1.25]
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
	find_node("ConfirmDialog").visible = false
	EventBus.emit_signal("grias_levelup_component_input_release")
	if was_yes:
		GameData.pay_cost(get_upgrade_cost())
		node.threshold_upgrades += 1
		node.threshold += 0.25
		update_text()
		EventBus.emit_signal("grias_levelup_major_component_upgrade", Color.white)

func get_upgrade_cost():
	return {C.ELEMENT_SOIL: floor(node.threshold_upgrades/2) + 1}
