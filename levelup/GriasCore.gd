extends MapEntity
class_name GriasCore

var frequency = 1
var power = 1
var element = "locked"
var directions = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
var counter = 0

func _ready():
	update_render()

func update_render():
	modulate = Util.get_element_color(element)

func on_map_place(tilemap_mgr, layer_name, cell):
	.on_map_place(tilemap_mgr, layer_name, cell)

func get_component_label():	
	match element:
		"water": return "Water Core"
		"soil": return "Soil Core"
		"sun": return "Sun Core"
		"decay": return "Decay Core"
		_: return "Unawakened Core"

func grias_generate_energy():
	if element == "locked":
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
	var core = preload("res://levelup/menu_items/AwakenCoreMenuItem.tscn").instance()
	core.setup(C.ELEMENT_SOIL)
	items.append(core)
	core = preload("res://levelup/menu_items/AwakenCoreMenuItem.tscn").instance()
	core.setup(C.ELEMENT_WATER)
	items.append(core)
	core = preload("res://levelup/menu_items/AwakenCoreMenuItem.tscn").instance()
	core.setup(C.ELEMENT_SUN)
	items.append(core)
	core = preload("res://levelup/menu_items/AwakenCoreMenuItem.tscn").instance()
	core.setup(C.ELEMENT_DECAY)
	items.append(core)
	return items

func modify_menu_items():
	return []

func component_change(change_type, cost_map, args):
	match change_type:
		"awaken_core":
			awaken_core(cost_map, args)

func awaken_core(cost_map, el):
	print("Awakening core for ", cost_map)
	GameData.pay_cost("grias_levelup_energy", cost_map)
	element = C.element_name(el)
	update_render()
	EventBus.emit_signal("grias_exit_component_mode")
	
