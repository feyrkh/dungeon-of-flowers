extends Node2D

var low_width = 33
var med_width = 23
var hi_width = 5

func _ready():
	$LowDmg.points[0].x = -low_width
	$LowDmg.points[-1].x = low_width
	$MedDmg.points[0].x = -med_width
	$MedDmg.points[-1].x = med_width
	$HiDmg.points[0].x = -hi_width
	$HiDmg.points[-1].x = hi_width

func setup(hi_width, med_width, low_width):
	self.hi_width = hi_width
	self.med_width = med_width
	self.low_width = low_width
