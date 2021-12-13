extends Node2D


const DIR_ONE = 0
const DIR_TWO_STRAIGHT = 1
const DIR_TWO_L = 2
const DIR_THREE = 3
const DIR_FOUR = 4

const FACING_UP = 0
const FACING_RIGHT = 90
const FACING_DOWN = 180
const FACING_LEFT = 270

var element = Util.ELEMENT_ALL
var direction = DIR_ONE
var facing = FACING_UP
var redirect_vector = [Vector2.UP]

func _ready():
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
		_: 
			$Sprite.texture = load("res://img/levelup/redirect_1.png")
			redirect_vector = [Vector2.UP]
	rotation_degrees = facing
	match element:
		C.ELEMENT_ALL: modulate = Color.white
		C.ELEMENT_SOIL: modulate = Color.chocolate
		C.ELEMENT_WATER: modulate = Color.aqua
		C.ELEMENT_SUN: modulate = Color.yellow
		C.ELEMENT_DECAY: modulate = Color.black
		_: modulate = Color.magenta
	

func get_next_direction():
	var retval = redirect_vector.pop_front()
	redirect_vector.push_back(retval)
	return retval
