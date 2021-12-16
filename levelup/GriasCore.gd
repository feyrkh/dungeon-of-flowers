extends MapEntity
class_name GriasCore

const COSTS = [1, 5, 10, 20, 30, 60, 90, 130, 170, 230, 290]

var level = 0
var frequency = 1
var power = 1
var element = -1
var directions = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
var counter = 0
var elements_unlocked = []
var directions_unlocked = []

func _ready():
	update_render()

func update_render():
	modulate = C.element_color(element)

func on_map_place(tilemap_mgr, layer_name, cell):
	.on_map_place(tilemap_mgr, layer_name, cell)

func get_component_label():
	if element >= 0:
		return C.element_name(element).capitalize()+" Core (Lvl "+str(level)+")"
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
	EventBus.emit_signal("grias_component_description", "A latent power slumbers in Grias' core. If she ingests a bit of the strange pollen, she might awaken it...")
	var items = []
	add_core_menu_item(items, C.ELEMENT_SOIL, "Awaken", 1)
	add_core_menu_item(items, C.ELEMENT_WATER, "Awaken", 1)
	add_core_menu_item(items, C.ELEMENT_SUN, "Awaken", 1)
	add_core_menu_item(items, C.ELEMENT_DECAY, "Awaken", 1)
	return items

func add_core_menu_item(items, element_id, prefix, cost):
	if self.element != element_id:
		var core = preload("res://levelup/menu_items/AwakenCoreMenuItem.tscn").instance()
		core.setup(element_id, prefix, elements_unlocked)
		items.append(core)

func add_upgrade_menu_items(items, element_id):
	pass

func modify_menu_items():
	EventBus.emit_signal("grias_component_description", "A well of "+C.element_name(element)+" power pulses in Grias' core. If she ingests more of the strange pollen, she might deepen the well, or change it entirely...")
	var items = []
	if element == C.ELEMENT_SOIL:
		add_upgrade_menu_items(items, C.ELEMENT_SOIL)
	if element == C.ELEMENT_WATER:
		add_upgrade_menu_items(items, C.ELEMENT_WATER)
	if element == C.ELEMENT_SUN:
		add_upgrade_menu_items(items, C.ELEMENT_SUN)
	if element == C.ELEMENT_DECAY:
		add_upgrade_menu_items(items, C.ELEMENT_DECAY)
	if element != C.ELEMENT_SOIL:
		add_core_menu_item(items, C.ELEMENT_SOIL, "Reawaken as", 1)
	if element != C.ELEMENT_WATER:
		add_core_menu_item(items, C.ELEMENT_WATER, "Reawaken as", 1)
	if element != C.ELEMENT_SUN:
		add_core_menu_item(items, C.ELEMENT_SUN, "Reawaken as", 1)
	if element != C.ELEMENT_DECAY:
		add_core_menu_item(items, C.ELEMENT_DECAY, "Reawaken as", 1)
	return items

func component_change(change_type, cost_map, args):
	match change_type:
		"awaken_core":
			awaken_core(cost_map, args)
			level = 1

func awaken_core(cost_map, el):
	print("Awakening core for ", cost_map)
	if elements_unlocked.find(el) < 0:
		GameData.pay_cost(cost_map)
		elements_unlocked.append(el)
	element = el
	update_render()
	EventBus.emit_signal("grias_exit_component_mode")

