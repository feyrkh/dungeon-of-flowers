extends MarginContainer

var node
var refund = {}
var map_coords
var tilemap_mgr

func _ready():
	find_node("ConfirmDialog").visible = false

func setup(_node, _tilemap_mgr, _refund, _map_coords):
	self.node = _node
	self.refund = _refund
	self.map_coords = _map_coords
	self.tilemap_mgr = _tilemap_mgr

func can_highlight():
	return true

func menu_item_highlighted():
	update_text()

func menu_item_unhighlighted():
	update_text()

func update_text():
	EventBus.emit_signal("grias_component_refund", refund)
	EventBus.emit_signal("grias_component_menu_text", "Destroy this node")

func component_input_started():
	find_node("DescriptionContainer").modulate = Color.yellow

func component_input_ended():
	find_node("DescriptionContainer").modulate = Color.white

func menu_item_action():
	EventBus.emit_signal("grias_levelup_component_input_capture", self)
	find_node("DescriptionLabel").text = "Destroy this node?  "
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
		EventBus.emit_signal("grias_destroy_node", node, map_coords, refund)
		EventBus.emit_signal("grias_levelup_major_component_upgrade", Color.black)
