extends MapEntity
class_name GriasCore

var frequency = 1
var power = 1
var element = -1
var directions = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
var counter = 0

func _ready():
	update_render()

func update_render():
	modulate = C.get_element_color(element)

func on_map_place(tilemap_mgr, layer_name, cell):
	.on_map_place(tilemap_mgr, layer_name, cell)

func get_component_label():	
	if element >= 0:
		return C.element_name(element).capitalize()+" Core"
	else:
		return "Unawakened Core"

func grias_generate_energy():
	if element == -1:
		return
	counter += 1
	if counter < frequency:
		return
	counter = 0
	EventBus.emit_signal("grias_generate_energy", self)

func _on_Timer_timeout():
	grias_generate_energy()

func get_next_direction():
	var retval = directions.pop_front()
	directions.push_back(retval)
	return retval

func get_component_menu_items():
	if get_component_label() == "Unawakened Core":
		return awaken_menu_items()
	else:
		return modify_menu_items()

func awaken_menu_items():
	var items = []
	add_core_menu_item(items, C.ELEMENT_SOIL, "Awaken")
	add_core_menu_item(items, C.ELEMENT_WATER, "Awaken")
	add_core_menu_item(items, C.ELEMENT_SUN, "Awaken")
	add_core_menu_item(items, C.ELEMENT_DECAY, "Awaken")
	return items

func add_core_menu_item(items, element_id, prefix):
	if self.element != element_id:
		var core = preload("res://levelup/menu_items/AwakenCoreMenuItem.tscn").instance()
		core.setup(element_id, prefix)
		items.append(core)

func modify_menu_items():
	var items = []
	add_core_menu_item(items, C.ELEMENT_SOIL, "Reawaken as")
	add_core_menu_item(items, C.ELEMENT_WATER, "Reawaken as")
	add_core_menu_item(items, C.ELEMENT_SUN, "Reawaken as")
	add_core_menu_item(items, C.ELEMENT_DECAY, "Reawaken as")
	return items

func component_change(change_type, cost_map, args):
	match change_type:
		"awaken_core":
			awaken_core(cost_map, args)

func awaken_core(cost_map, el):
	print("Awakening core for ", cost_map)
	GameData.pay_cost("grias_levelup_energy", cost_map)
	element = el
	update_render()
	EventBus.emit_signal("grias_exit_component_mode")
	
