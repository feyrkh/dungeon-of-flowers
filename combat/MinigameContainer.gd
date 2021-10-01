extends CenterContainer

var original_position:Vector2
var squished_position:Vector2
var start_position:Vector2
var target_position:Vector2
var move_time
var t

func _ready():
	set_process(false)
	original_position = rect_global_position
	squished_position = rect_global_position - Vector2(original_position.x/3, 0)

func _process(delta):
	t = min(1.0, t+delta/move_time)
	self.rect_global_position = start_position.linear_interpolate(target_position, t)
	if t >= 1.0:
		set_process(false)

func set_target_position(pos, move_time):
	set_process(true)
	start_position = rect_global_position
	target_position = pos
	self.move_time = move_time
	self.t = 0.0

func squish_for_minigame(move_time=0.5):
	set_target_position(squished_position, move_time)

func unsquish_for_minigame(move_time=0.5):
	set_target_position(original_position, move_time)
