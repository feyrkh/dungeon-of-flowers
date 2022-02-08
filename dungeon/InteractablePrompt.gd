extends Control

func _ready():
	visible = false
	EventBus.connect("update_interactable", self, "on_update_interactable")

func on_update_interactable(interactable_list):
	if interactable_list == null or interactable_list.size() == 0:
		visible = false
	else:
		visible = true
		var label_text = null
		if interactable_list[0].has_method("get_interactable_prompt"):
			label_text = interactable_list[0].get_interactable_prompt()
		if label_text == null:
			label_text = ""
			visible = false
		$Label.text = label_text
