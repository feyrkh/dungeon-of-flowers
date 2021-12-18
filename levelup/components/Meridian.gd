extends Node2D


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

func _ready():
	render_component()

func get_meridian_efficiency():
	return EFFICIENCY[efficiency_level]

func get_component_label():
	if element != C.ELEMENT_ALL:
		return C.element_name(element).capitalize()+" Meridian (Lvl "+str(efficiency_level+range_level+1)+")"
	else:
		return "Meridian (Lvl "+str(efficiency_level+range_level+1)+")"

func unlock_element(_element, cost):
	element = _element
	for k in cost:
		investment[k] = investment.get(k, 0) + cost[k]
	render_component()

func unlock_direction(_direction):
	if !unlocked_directions.has(_direction):
		unlocked_directions.append(_direction)
	direction = _direction
	render_component()

func unlock_efficiency_level(_level):
	if max_unlocked_efficiency_level < _level:
		max_unlocked_efficiency_level = _level
	render_component()

func unlock_range_level(_level):
	if max_unlocked_range_level < _level:
		max_unlocked_range_level = _level
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
	match element:
		C.ELEMENT_ALL:
			investment[C.ELEMENT_SOIL] = 1
			investment[C.ELEMENT_WATER] = 1
			investment[C.ELEMENT_SUN] = 1
		C.ELEMENT_SOIL:
			investment[element] = 1
		C.ELEMENT_WATER:
			investment[element] = 1
		C.ELEMENT_SUN:
			investment[element] = 1
		C.ELEMENT_DECAY:
			investment[element] = 1
		_:
			pass
	modulate = C.element_color(element)
	match efficiency_level:
		0:
			scale = Vector2(0.33, 0.33)
		1:
			scale = Vector2(0.66, 0.66)
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

func cursor_rotate(direction):
	facing = posmod(round(facing + 90*direction), 360)
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
	return menu_items


func get_description():
	var desc = "An orderly pathway for energy, allows "+C.element_name(element)+" energy to flow with less power loss and can even redirect energy with additional upgrades.\n"
	desc += "Energy efficiency: "+str(round(get_meridian_efficiency()*100))+"%"
	if range_level > 0:
		desc += "\nTunneling distance: "+str(range_level)
	return desc
