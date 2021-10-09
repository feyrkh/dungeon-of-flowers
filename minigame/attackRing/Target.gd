extends Node2D

var low_width = 33
var med_width = 23
var hi_width = 5
var already_cleared = false

func _ready():
	$LowDmg.scale.x = calc_width(low_width)
	$MedDmg.scale.x = calc_width(med_width)
	$HiDmg.scale.x = calc_width(hi_width)
	var lowArea := $LowArea
	lowArea.target_color = Color.white 
	#lowArea.target_color = $LowDmg.default_color
	lowArea.get_node("CollisionShape2D").shape = RectangleShape2D.new()
	lowArea.get_node("CollisionShape2D").shape.extents = Vector2(low_width, 33)
	var medArea := $MedArea
	medArea.target_color = Color.white
	#medArea.target_color = $MedDmg.default_color
	medArea.get_node("CollisionShape2D").shape = RectangleShape2D.new()
	medArea.get_node("CollisionShape2D").shape.extents = Vector2(med_width, 33)
	var hiArea := $HiArea
	hiArea.target_color = Color.white
	#hiArea.target_color = $HiDmg.default_color
	hiArea.get_node("CollisionShape2D").shape = RectangleShape2D.new()
	hiArea.get_node("CollisionShape2D").shape.extents = Vector2(hi_width, 33)

func calc_width(pixels):
	return pixels/14
	

func setup(hi, med, low):
	self.hi_width = hi 
	self.med_width = med 
	self.low_width = low 

func clear_target(max_multiplier):
	if already_cleared:
		return
	already_cleared = true
	if max_multiplier != $LowArea.multiplier:
		$LowDmg.modulate = Color.transparent
	if max_multiplier != $MedArea.multiplier:
		$MedDmg.modulate = Color.transparent
	if max_multiplier != $HiArea.multiplier:
		$HiDmg.modulate = Color.transparent
		
	$LowArea.multiplier = 0
	$MedArea.multiplier = 0
	$HiArea.multiplier = 0
