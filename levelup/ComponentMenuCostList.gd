extends HBoxContainer

var SPRITE_SCALE = Vector2(0.5, 0.5)

func _ready():
	EventBus.connect("grias_component_cost", self, "grias_component_cost")

func grias_component_cost(cost_map):
	Util.delete_children(self)
	for child in get_children():
		child.visible = false
	if cost_map == null:
		visible = false
		return
	elif cost_map.size() == 0:
		visible = true
		var label = preload("res://levelup/menu_items/CostListLabel.tscn").instance()
		label.text = "Cost: FREE"
		add_child(label)

	else:
		visible = true
		for element_id in C.ELEMENT_IDS:
			if !cost_map.has(element_id):
				continue
			var element_name = C.element_name(element_id).capitalize()
			var sprite = TextureRect.new()
			sprite.texture = C.element_image(element_id)
			add_child(sprite)
			sprite.set_stretch_mode(5)
			sprite.expand = true
			sprite.rect_scale = SPRITE_SCALE
			sprite.rect_min_size = sprite.texture.get_size()*0.7
			sprite.size_flags_horizontal = 0
			var label = preload("res://levelup/menu_items/CostListLabel.tscn").instance()
			label.text = str(cost_map[element_id])+"   "
			#label.size_flags_horizontal = 0
			add_child(label)
