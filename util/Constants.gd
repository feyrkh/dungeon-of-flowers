extends Node

const HALF_VECTOR = Vector2(0.5, 0.5)

const ELEMENT_SOIL = 0
const ELEMENT_WATER = 1
const ELEMENT_SUN = 2
const ELEMENT_DECAY = 3
const ELEMENT_ALL = 4

const ELEMENT_IDS = [ELEMENT_SOIL, ELEMENT_WATER, ELEMENT_SUN, ELEMENT_DECAY]
const ELEMENT_NAME = ["soil", "water", "sun", "decay", "all"]

static func element_name(element_id):
	if element_id < 0 or element_id >= ELEMENT_NAME.size():
		return "element_"+element_id
	return ELEMENT_NAME[element_id]

static func element_image(element_id):
	return load("res://img/levelup/"+element_name(element_id)+"_egg.png")

static func element_color(element_name):
	match element_name:
		C.ELEMENT_ALL: return Color.white
		C.ELEMENT_WATER: return Color.aqua
		C.ELEMENT_SOIL: return Color.gray
		C.ELEMENT_SUN: return Color.yellow
		C.ELEMENT_DECAY: return Color.purple
		_: return Color.white
