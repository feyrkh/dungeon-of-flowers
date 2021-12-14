extends Node2D


const DIR_ONE = 0
const DIR_TWO_STRAIGHT = 1
const DIR_TWO_L = 2
const DIR_THREE = 3
const DIR_FOUR = 4
const DIR_NONE = 5

const FACING_UP = 0
const FACING_RIGHT = 90
const FACING_DOWN = 180
const FACING_LEFT = 270

const ROTATION_PER_LEVEL = 30
const EFFICIENCY = [0.75, 0.9, 1.0]

var efficiency_level = 2
var range_level = 3
var element = C.ELEMENT_ALL
var direction = DIR_NONE
var facing = FACING_UP
var redirect_vector = null
var investment = {}

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

func render_component():
	match direction:
		DIR_ONE:
			$Sprite.texture = load("res://img/levelup/redirect_1.png")
			redirect_vector = [Vector2.UP]
		DIR_TWO_STRAIGHT: 
			$Sprite.texture = load("res://img/levelup/redirect_2b.png")
			redirect_vector = [Vector2.UP, Vector2.DOWN]
		DIR_TWO_L: 
			$Sprite.texture = load("res://img/levelup/redirect_2a.png")
			redirect_vector = [Vector2.UP, Vector2.RIGHT]
		DIR_THREE: 
			$Sprite.texture = load("res://img/levelup/redirect_3.png")
			redirect_vector = [Vector2.UP, Vector2.RIGHT, Vector2.LEFT]
		DIR_FOUR: 
			$Sprite.texture = load("res://img/levelup/redirect_4.png")
			redirect_vector = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
		DIR_NONE:
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
		set_process(true)
	else:
		set_process(false)

func _process(delta):
	rotation_degrees -= ROTATION_PER_LEVEL * delta * range_level

func get_next_direction():
	if redirect_vector == null:
		return null
	var retval = redirect_vector.pop_front()
	redirect_vector.push_back(retval)
	return retval

func spark_arrived(spark, tile_coords):
	if element != C.ELEMENT_ALL and element != spark.element:
		return
	spark.add_meridian_energy(get_meridian_efficiency())
	spark.redirect(get_next_direction())

func get_component_menu_items():
	EventBus.emit_signal("grias_component_description", get_description())
	var menu_items = []
	var meridian_item = preload("res://levelup/menu_items/BuildMeridianMenuItem.tscn").instance()
	meridian_item.upgrade(self)
	menu_items.append(meridian_item)
	return menu_items

func get_description():
	var desc = "An orderly pathway for energy, allows "+C.element_name(element)+" energy to flow with less power loss and can even redirect energy with additional upgrades.\n"
	desc += "Energy efficiency: "+str(round(get_meridian_efficiency()*100))+"%\nRange boost: "+str(range_level)
	return desc
