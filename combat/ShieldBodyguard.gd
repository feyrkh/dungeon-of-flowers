extends ShieldHard

const LEFT_ALLY = 1920/2.0 - 570
const RIGHT_ALLY = 1920/2.0 + 580
const CENTER_SCREEN = 1920/2
const MIN_SIZE = 0.1
const MAX_SIZE = 1.0
const MAX_DIST_FROM_ALLY = RIGHT_ALLY - CENTER_SCREEN

var last_x = 0

func _ready():
	recalc_size()

func _physics_process(delta):
	if global_position.x != last_x:
		last_x = global_position.x
		recalc_size()

func recalc_size():
	var distance_from_ally = min(MAX_DIST_FROM_ALLY, min(max(0, global_position.x - LEFT_ALLY), max(0, RIGHT_ALLY - global_position.x)))
	var pct_dist = distance_from_ally / MAX_DIST_FROM_ALLY
	var size_multiplier = lerp(MAX_SIZE, MIN_SIZE, pct_dist)
	var size = shield_data.get("shield_size", 1.0)
	scale = Vector2(size*size_multiplier, size/2*size_multiplier)
