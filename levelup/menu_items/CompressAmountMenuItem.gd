extends VBoxContainer

onready var CompressSelector = find_node("CompressSelector")

var existing_node

func setup(_existing_node):
	existing_node = _existing_node
	EventBus.connect("grias_levelup_major_component_upgrade", self, "on_component_upgrade")
	update_text()

func on_component_upgrade(unused):
	update_text()

func can_highlight():
	return true

func menu_item_highlighted():
	find_node("ui_left").visible = true
	find_node("ui_right").visible = true
	find_node("ThresholdLabel").modulate = Color.yellow
	update_text()

func menu_item_unhighlighted():
	find_node("ThresholdLabel").modulate = Color.white
	find_node("ui_left").visible = false
	find_node("ui_right").visible = false
	update_text()

func unselected_component_input(event):
	if event.is_action_pressed("ui_left"):
		adjust_threshold(-1)
	elif event.is_action_pressed("ui_right"):
		adjust_threshold(1)
	update_text()

func update_text():
	find_node("DescriptionLabel").text = "Compression threshold:         "
	find_node("ThresholdLabel").text = "%.2f" % [existing_node.threshold]
	EventBus.emit_signal("grias_component_menu_text", "Energy will be absorbed until it exceeds the threshold, then emitted in the same direction as the last energy spark.")

func adjust_threshold(dir):
	existing_node.threshold = wrapi(round(existing_node.threshold / 0.25)+dir, 1, existing_node.threshold_upgrades+5) * 0.25
	update_text()
