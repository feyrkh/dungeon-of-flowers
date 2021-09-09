extends Label

var velocity

func set_damage(damage):
	text = "-" + str(damage)+" hp"

func _ready():
	velocity = Vector2((randf()-0.5) * 300, -200)

func _process(delta):
	self.rect_position = self.rect_position + velocity * delta
	velocity += Vector2(0, 150) * delta
	if self.rect_position.y > 1000:
		queue_free()
