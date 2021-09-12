extends ColorRect

signal fade_complete

export(float) var pixelize_level = 0.01
var shader:ShaderMaterial
var start:float
var target:float
var fade_secs:float
var counter:float
var fading = false

func _ready():
	#self.rect_size = get_viewport().get_rect().size
	shader = self.material

func fade_out(pixelize_level:float, fade_secs:float):
	start = 0
	target = pixelize_level
	self.fade_secs = fade_secs
	counter = 0
	fading = true

func fade_in(pixelize_level:float, fade_secs:float):
	start = pixelize_level
	target = 0
	self.fade_secs = fade_secs
	counter = 0
	fading = true

func _process(delta):
	if !fading:
		return
	counter += delta
	if counter < fade_secs:
		var cur_level = lerp(start, target, counter/fade_secs)
		shader.set_shader_param("size_x", cur_level)
		shader.set_shader_param("size_y", cur_level)
	else:
		shader.set_shader_param("size_x", target)
		shader.set_shader_param("size_y", target)
		emit_signal("fade_complete")
		fading = false
