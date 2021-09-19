extends Control

onready var categories = [find_node("IconFight"), find_node("IconSkill"), find_node("IconDefend"), find_node("IconItem")]
onready var category_ys = [categories[0].rect_position.y, categories[1].rect_position.y, categories[2].rect_position.y, categories[3].rect_position.y, ]
onready var anim = find_node("AnimationPlayer")
onready var bouncers = [get_node("CharSwitchLeft/Bouncer"), get_node("CharSwitchRight/Bouncer")]

export(Color) var selected_color = Color.white
export(Color) var deselected_color = Color(0.6, 0.6, 0.6)

func hide():
	anim.play("fade")
	yield(anim, "animation_finished")
	self.visible = false

func show(selected_idx=0):
	select(selected_idx)
	for bouncer in bouncers:
		bouncer.reset()
	
	self.visible = true
	anim.play_backwards("fade")
	yield(anim, "animation_finished")

func select(selected_idx=0):
	for i in range(categories.size()):
		if i == selected_idx:
			categories[i].modulate = selected_color
			categories[i].get_node("Label").visible = true
			if i < category_ys.size():
				categories[i].rect_position.y = category_ys[i] - 10
			#categories[i].rect_scale = Vector2(1, 1)
		else:
			categories[i].modulate = deselected_color
			categories[i].get_node("Label").visible = false
			if i < category_ys.size():
				categories[i].rect_position.y = category_ys[i]
			#categories[i].rect_scale = Vector2(0.6, 0.6)
	return selected_idx

func select_next_category(selected_category_idx, direction):
	if (selected_category_idx+direction >= categories.size()):
		selected_category_idx = categories.size() - 2
	var new_category_idx = (selected_category_idx + direction) % (categories.size() - 1)
	if new_category_idx < 0: 
		new_category_idx += (categories.size() - 1)
	select(new_category_idx)
	return new_category_idx

func select_no_category():
	select(null)
