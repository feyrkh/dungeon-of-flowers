extends MapEntity

const ROTATION_PER_LEVEL = 30
const EFFICIENCY = [0.75, 0.9, 1.0, 1.1]

var efficiency_level = 0
var range_level = 0
var element = C.ELEMENT_ALL
var direction = C.MERIDIAN_DIR_NONE
var facing = C.FACING_UP
var redirect_vector = null
var investment = {}
var unlocked_directions = [0]
var max_unlocked_efficiency_level = 0
var max_unlocked_range_level = 0

func grias_pre_save_levelup():
	var save_data = {
		"efficiency_level": efficiency_level,
		"range_level": range_level,
		"element": element,
		"direction": direction,
		"facing": facing,
		"redirect_vector": redirect_vector,
		"investment": investment,
		"unlocked_directions": unlocked_directions,
		"max_unlocked_efficiency_level": max_unlocked_efficiency_level,
		"max_unlocked_range_level": max_unlocked_range_level,
	}
	update_config(save_data)

func on_map_place(tilemap_mgr, layer_name, cell):
	.on_map_place(tilemap_mgr, layer_name, cell)
	position = position + Vector2(32, 32)
	render_component()

func _ready():
	EventBus.connect("grias_pre_save_levelup", self, "grias_pre_save_levelup")
	render_component()

func get_meridian_efficiency():
	return EFFICIENCY[efficiency_level]

func get_component_label():
	if element != C.ELEMENT_ALL:
		return C.element_name(element).capitalize()+" Meridian (Lvl "+str(max_unlocked_efficiency_level)+")"
	else:
		return "Meridian (Lvl "+str(max_unlocked_efficiency_level)+")"

func add_investment(cost):
	if cost == null:
		return
	for k in cost:
		investment[k] = investment.get(k, 0) + cost[k]

func unlock_element(_element, cost):
	element = _element
	add_investment(cost)
	render_component()

func unlock_direction(_direction, cost):
	if !unlocked_directions.has(_direction):
		unlocked_directions.append(_direction)
	direction = _direction
	add_investment(cost)
	render_component()

func unlock_efficiency_level(_level, cost):
	if max_unlocked_efficiency_level < _level:
		max_unlocked_efficiency_level = _level
	add_investment(cost)
	render_component()

func unlock_range_level(_level, cost):
	if max_unlocked_range_level < _level:
		max_unlocked_range_level = _level
	add_investment(cost)
	render_component()

func render_component():
	match direction:
		C.MERIDIAN_DIR_1:
			$Sprite.texture = load("res://img/levelup/redirect_1.png")
			redirect_vector = [Vector2.UP]
		C.MERIDIAN_DIR_2a:
			$Sprite.texture = load("res://img/levelup/redirect_2b.png")
			redirect_vector = [Vector2.UP, Vector2.DOWN]
		C.MERIDIAN_DIR_2b:
			$Sprite.texture = load("res://img/levelup/redirect_2a.png")
			redirect_vector = [Vector2.UP, Vector2.RIGHT]
		C.MERIDIAN_DIR_3:
			$Sprite.texture = load("res://img/levelup/redirect_3.png")
			redirect_vector = [Vector2.UP, Vector2.RIGHT, Vector2.LEFT]
		C.MERIDIAN_DIR_4:
			$Sprite.texture = load("res://img/levelup/redirect_4.png")
			redirect_vector = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
		C.MERIDIAN_DIR_NONE:
			$Sprite.texture = load("res://img/levelup/whirl.png")
			redirect_vector = null
		_:
			$Sprite.texture = load("res://img/levelup/redirect_1.png")
			redirect_vector = [Vector2.UP]
	rotation_degrees = facing

	modulate = C.element_color(element)
	match efficiency_level:
		0:
			scale = Vector2(0.33, 0.33)
		1:
			scale = Vector2(0.66, 0.66)
		2:
			scale = Vector2(0.9, 0.9)
		_:
			scale = Vector2.ONE
	if range_level > 0:
		if direction == C.MERIDIAN_DIR_NONE:
			set_process(true)
	else:
		set_process(false)

func _process(delta):
	if direction == C.MERIDIAN_DIR_NONE:
		rotation_degrees -= ROTATION_PER_LEVEL * delta * range_level

func can_cursor_rotate():
	return direction != C.MERIDIAN_DIR_NONE

func cursor_rotate(_direction):
	facing = posmod(round(facing + 90*_direction), 360)
	render_component()

func get_next_direction():
	if redirect_vector == null:
		return null
	var retval:Vector2 = redirect_vector.pop_front()
	redirect_vector.push_back(retval)
	return retval.rotated(deg2rad(facing))

func spark_arrived(spark, tile_coords):
	if element != C.ELEMENT_ALL and element != spark.element:
		return
	spark.add_meridian_energy(get_meridian_efficiency())
	spark.tunnel(range_level)
	spark.redirect(get_next_direction())

func get_component_menu_items():
	EventBus.emit_signal("grias_component_description", get_description())
	var menu_items = []
	var meridian_item = preload("res://levelup/menu_items/BuildMeridianMenuItem.tscn").instance()
	meridian_item.upgrade(self)
	menu_items.append(meridian_item)
	var shape_item = preload("res://levelup/menu_items/MeridianShapeMenuItem.tscn").instance()
	shape_item.setup(self, unlocked_directions)
	menu_items.append(shape_item)
	var efficiency_item = preload("res://levelup/menu_items/EnergyEfficiencyMenuItem.tscn").instance()
	efficiency_item.setup(self, EFFICIENCY[efficiency_level], max_unlocked_efficiency_level)
	menu_items.append(efficiency_item)
	var range_item = preload("res://levelup/menu_items/EnergyRangeMenuItem.tscn").instance()
	range_item.setup(self, range_level, max_unlocked_range_level)
	menu_items.append(range_item)
	var delete_item = preload("res://levelup/menu_items/DeleteNodeMenuItem.tscn").instance()
	delete_item.setup(self, tilemap_mgr, GameData.partial_investment_refund(investment), map_position)
	menu_items.append(delete_item)
	return menu_items

func get_description():
	var desc = "An orderly pathway for energy, allows "+C.element_name(element)+" energy to flow with less power loss and can even redirect energy with additional upgrades.\n"
	desc += "Energy efficiency: "+str(round(get_meridian_efficiency()*100))+"%"
	if range_level > 0:
		desc += "\nTunneling distance: "+str(range_level)
	return desc
