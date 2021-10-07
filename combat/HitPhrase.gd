extends Control

const GRAVITY = Vector2(0, 700)

var vel
var rot
var alpha

func setup(phrase):
	$Label.text = phrase

func _ready():
	alpha = 2
	var rot_dir = 1
	if randf() >= 0.5:
		rot_dir = -1
	rot = rand_range(10, 20) * rot_dir
	vel = Vector2(rand_range(30, 60) * rot_dir, -600)
	
func _process(delta):
	self.rect_position += vel * delta
	vel += GRAVITY * delta
	self.rect_rotation += rot * delta
	alpha -= delta
	if alpha < 1:
		self.modulate.a = alpha
	if alpha <= 0.05:
		self.queue_free()
