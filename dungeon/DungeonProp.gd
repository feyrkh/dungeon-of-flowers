extends Spatial

export(Vector3) var min_translation = Vector3.ZERO
export(Vector3) var max_translation = Vector3.ZERO
export(Vector3) var min_rotation_degrees = Vector3.ZERO
export(Vector3) var max_rotation_degrees = Vector3.ZERO
export(float) var appearance_chance = 0.1
export(Vector3) var min_scale = Vector3.ONE
export(Vector3) var max_scale = Vector3.ONE
export(Vector3) var flipped_translation = Vector3.ZERO
export(Vector3) var flipped_rotation = Vector3.ZERO

func _ready():
	if randf() > appearance_chance:
		queue_free()
		return
	var flipped = randf() > 0.5
	transform.basis = transform.basis.rotated(Vector3.RIGHT, deg2rad(rand_range(min_rotation_degrees.x, max_rotation_degrees.x)))
	transform.basis = transform.basis.rotated(Vector3.UP, deg2rad(rand_range(min_rotation_degrees.y, max_rotation_degrees.y)))
	transform.basis = transform.basis.rotated(Vector3.FORWARD, deg2rad(rand_range(min_rotation_degrees.z, max_rotation_degrees.z)))
	if flipped and flipped_rotation != Vector3.ZERO:
		transform = transform.rotated(Vector3.RIGHT, deg2rad(flipped_rotation.x))
		transform = transform.rotated(Vector3.UP, deg2rad(flipped_rotation.y))
		transform = transform.rotated(Vector3.FORWARD, deg2rad(flipped_rotation.z))
	transform = transform.translated(random_vector(min_translation, max_translation))
	transform = transform.scaled(random_vector(min_scale, max_scale))
	if flipped and flipped_translation != Vector3.ZERO:
		transform = transform.translated(flipped_translation)

func random_vector(min_vec:Vector3, max_vec:Vector3) -> Vector3:
	return Vector3(rand_range(min_vec.x, max_vec.x), rand_range(min_vec.y, max_vec.y), rand_range(min_vec.z, max_vec.z))
