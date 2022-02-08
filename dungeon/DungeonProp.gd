extends Spatial

export(float) var appearance_chance = 0.1
export(Vector3) var min_translation = Vector3.ZERO
export(Vector3) var max_translation = Vector3.ZERO
export(Vector3) var min_rotation_degrees = Vector3.ZERO
export(Vector3) var max_rotation_degrees = Vector3.ZERO
export(Vector3) var min_scale = Vector3.ONE
export(Vector3) var max_scale = Vector3.ONE
export(Vector3) var flipped_translation = Vector3.ZERO
export(Vector3) var flipped_rotation = Vector3.ZERO

export(Vector3) var writhe_trans = Vector3.ZERO
export(Vector3) var writhe_rotate = Vector3.ZERO
export(Vector3) var writhe_scale = Vector3.ZERO
export(float) var writhe_time = 3.0

var orig_rotate
var orig_scale
var orig_translate

func _ready():
	if randf() > appearance_chance:
		queue_free()
		return
	var flipped = randf() > 0.5
	rotation_degrees += random_vector(min_rotation_degrees, max_rotation_degrees)
	if flipped and flipped_rotation != Vector3.ZERO:
		rotation_degrees += flipped_rotation
	translation += (random_vector(min_translation, max_translation))
	scale = (random_vector(min_scale, max_scale))
	if flipped and flipped_translation != Vector3.ZERO:
		translation += (flipped_translation)
	if writhe_trans == Vector3.ZERO and writhe_rotate == Vector3.ZERO and writhe_scale == Vector3.ZERO:
		set_process(false)

func random_vector(min_vec:Vector3, max_vec:Vector3) -> Vector3:
	return Vector3(rand_range(min_vec.x, max_vec.x), rand_range(min_vec.y, max_vec.y), rand_range(min_vec.z, max_vec.z))


var t = rand_range(0.0, 1.0)
var scale_offset = rand_range(0.0, 1.0)
var rotate_offset = rand_range(0.0, 1.0)
var translate_offset = rand_range(0.0, 1.0)

func _process(delta):
	if orig_rotate == null:
		orig_rotate = rotation_degrees
		orig_scale = scale
		orig_translate = translation

	scale_offset += delta/writhe_time
	rotate_offset += delta/writhe_time
	translate_offset += delta/writhe_time
	if scale_offset >= 2: scale_offset -= 2
	if rotate_offset >= 2: rotate_offset -= 2
	if translate_offset >= 2: translate_offset -= 2


	if writhe_trans != Vector3.ZERO:
		translation = orig_translate + Vector3.ZERO.linear_interpolate(writhe_trans, translate_time(t + translate_offset))
	if writhe_rotate != Vector3.ZERO:
		rotation_degrees = orig_rotate + Vector3.ZERO.linear_interpolate(writhe_rotate, translate_time(t + rotate_offset))
	if writhe_scale != Vector3.ZERO:
		scale = orig_scale + Vector3.ZERO.linear_interpolate(writhe_scale, translate_time(t + scale_offset))

	#transform.basis = transform.basis.rotated(Vector3.RIGHT, lerp_angle(0, deg2rad(359), t))

func translate_time(_t):
	if _t > 2: _t -= 2
	if _t >= 1: _t = 2-_t
	return _t
