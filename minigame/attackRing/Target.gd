extends Node2D

var low_width = 33
var med_width = 23
var hi_width = 5

func _ready():
	var med_colors = PoolColorArray($MedDmg.gradient.colors)
	var med_offsets = $MedDmg.gradient.offsets
	$MedDmg.gradient = Gradient.new()
	$MedDmg.gradient.colors = med_colors
	$MedDmg.gradient.offsets = med_offsets
	#for i in range($MedDmg.gradient.colors.size()):
	#	var c = $MedDmg.gradient.colors[i] 
	#	$MedDmg.gradient.colors[i] = Color(c.r, c.g, c.b)
	$LowDmg.points[0].x = -low_width
	$LowDmg.points[-1].x = low_width
	$MedDmg.points[0].x = -med_width
	$MedDmg.points[-1].x = med_width
	$HiDmg.points[0].x = -hi_width
	$HiDmg.points[-1].x = hi_width
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

func setup(hi_width, med_width, low_width):
	self.hi_width = hi_width
	self.med_width = med_width
	self.low_width = low_width

func clear_target():
	$LowArea.multiplier = 0
	$MedArea.multiplier = 0
	$HiArea.multiplier = 0
	var low_gray = $LowDmg.default_color.gray()
	var hi_gray = $HiDmg.default_color.gray()
	$LowDmg.default_color = Color(low_gray, low_gray, low_gray)
	for i in range($MedDmg.gradient.colors.size()):
		var med_gray = $MedDmg.gradient.colors[i].gray()
		$MedDmg.gradient.colors[i] = Color(med_gray, med_gray, med_gray)
	$HiDmg.default_color = Color(hi_gray, hi_gray, hi_gray)
