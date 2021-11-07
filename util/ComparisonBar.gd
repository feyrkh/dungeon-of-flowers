extends Node2D

var left_val = 0 setget set_left_val
var right_val = 0 setget set_right_val
var cur_middle
var total_length

func _ready():
	total_length = $RightSide.points[0].x - $LeftSide.points[0].x
	cur_middle = int(total_length/2.0)
	set_left_val(left_val)
	set_right_val(right_val)
	$LeftSide.light_mask = light_mask
	$RightSide.light_mask = light_mask

func set_left_val(v):
	left_val = v
	update_comparison()

func set_right_val(v):
	right_val = v
	update_comparison()

func update_comparison():
	var new_pct
	if left_val == 0 and right_val == 0:
		new_pct = 0.5
	else:
		new_pct = left_val / (left_val + right_val)
	var new_middle = int(total_length*new_pct)
	if new_middle != cur_middle:
		throw_sparks(new_middle)

func throw_sparks(new_middle):
	if $Tween.is_active():
		$Tween.remove_all()
	$Tween.interpolate_method(self, "move_middle", cur_middle, new_middle, 0.5)
	$Tween.start()

func move_middle(new_middle):
	$LeftSide.points[1].x = new_middle
	$RightSide.points[1].x = new_middle
	$LeftDegrade.position.x = new_middle
	$RightDegrade.position.x = new_middle
	if new_middle < cur_middle:
		if !$LeftDegrade.emitting:
			$LeftDegrade.emitting = true
			$RightDegrade.emitting = false
	elif new_middle > cur_middle:
		if !$RightDegrade.emitting:
			$RightDegrade.emitting = true
			$LeftDegrade.emitting = false
	else:
		$RightDegrade.emitting = false
		$LeftDegrade.emitting = false
	cur_middle = new_middle
