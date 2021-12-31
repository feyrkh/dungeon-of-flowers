tool extends Sprite3D

enum SizeAxis {WIDTH, HEIGHT}

export(float) var size_in_units = 3
export(SizeAxis) var size_axis = SizeAxis.WIDTH

func _ready() -> void:
	update_size()

func update_size():
	if !texture:
		return
	var pixels
	if size_axis == SizeAxis.WIDTH:
		pixels = texture.get_size().x
	else:
		pixels = texture.get_size().y
	pixel_size = size_in_units/pixels
	offset.y = pixels/4.0
