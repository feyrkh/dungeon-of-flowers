extends Node2D

const SCREEN_WIDTH = 1920
const NORMAL_VELOCITY = 200
const SPRINT_VELOCITY = 100

var shield_data:Dictionary
var speed_bonus = 1.0
var durability = 1
var 

func setup(ally, _shield_data):
	self.shield_data = _shield_data
	global_position = ally.get_target(0) + shield_data.get("pos", Vector2.ZERO)
	scale = shield_data.get("shield_size", Vector2.ONE)
	speed_bonus = shield_data.get("shield_speed", 1.0)
	
