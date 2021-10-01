extends Control

const STATUS_CATEGORY = 4

onready var categories = [find_node("IconFight"), find_node("IconSkill"), find_node("IconDefend"), find_node("IconItem")]
onready var category_ys = [categories[0].rect_position.y, categories[1].rect_position.y, categories[2].rect_position.y, categories[3].rect_position.y, ]
onready var anim = find_node("AnimationPlayer")
onready var bouncers = [get_node("CharSwitchLeft/Bouncer"), get_node("CharSwitchRight/Bouncer")]


var ally_data

func setup(_ally_data):
	self.ally_data = _ally_data
	for category in categories:
		category.setup(ally_data)

func hide():
	anim.play("fade")
	yield(anim, "animation_finished")
	self.visible = false
	unhighlight_icon(STATUS_CATEGORY) # status icon doesn't get properly reset usually

func show(selected_idx=0):
	if (category_ys.size() <= STATUS_CATEGORY):
		category_ys.append(categories[STATUS_CATEGORY].rect_position.y)
	select(selected_idx)
	for bouncer in bouncers:
		bouncer.reset()
	
	self.visible = true
	anim.play_backwards("fade")
	yield(anim, "animation_finished")

func unhighlight_icon(i):
	categories[i].unhighlight()

func select(selected_idx=0):
	for i in range(categories.size()):
		if i == selected_idx:
			categories[i].highlight()
			#categories[i].rect_scale = Vector2(1, 1)
		else:
			unhighlight_icon(i)
	return selected_idx

func select_next_category(selected_category_idx, direction):
	for i in range(4):
		if (selected_category_idx+direction >= categories.size()):
			selected_category_idx = categories.size() - 2
		var new_category_idx = (selected_category_idx + direction) % (categories.size() - 1)
		if new_category_idx < 0: 
			new_category_idx += (categories.size() - 1)
		if categories[new_category_idx].is_selectable():
			select(new_category_idx)
			return new_category_idx
		selected_category_idx = new_category_idx

func select_no_category():
	select(null)
