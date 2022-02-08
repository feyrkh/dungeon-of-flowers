tool extends Spatial

const FRONT_VEC = Vector3(0, 0, 1)
const BACK_VEC = Vector3(0, 0, -1)
const LEFT_VEC = Vector3(-1, 0, 0)
const RIGHT_VEC = Vector3(1, 0, 0)
const FRONT_LEFT_VEC = Vector3(-0.707, 0, 0.707)
const BACK_LEFT_VEC = Vector3(-0.707, 0, -0.707)
const FRONT_RIGHT_VEC = Vector3(0.707, 0, 0.707)
const BACK_RIGHT_VEC = Vector3(0.707, 0, -0.707)
const VALID_FRAME_NAMES = ["front", "back", "left", "right", "front-left", "back-left", "front-right", "back-right"]
const VALID_FRAME_VECS = [FRONT_VEC, BACK_VEC, LEFT_VEC, RIGHT_VEC, FRONT_LEFT_VEC, BACK_LEFT_VEC, FRONT_RIGHT_VEC, BACK_RIGHT_VEC]

export(Array, String) var defined_frames = ["front", "back", "left", "front-left", "back-left"]
export(Array, Texture) var frames
export(Array, Vector3) var image_offsets
export(float) var width_in_meters = 1

# views[VECTOR] = [texture, pixel_size, aspect_ratio, flip]
var views = {}
var current_view_vec = null

func _get_configuration_warning() -> String:
	if Engine.editor_hint:
		refresh_perspective(Vector3.BACK)
	if defined_frames.size() != frames.size():
		return "Must have exactly the same number of frame textures as entries in defined_frames"
	if defined_frames.size() != image_offsets.size():
		return "Must have exactly the same number of image offsets as entries in defined_frames"
	return ""

func _ready():
	EventBus.connect("refresh_perspective_sprites", self, "refresh_perspective")
	for i in defined_frames.size():
		var idx = VALID_FRAME_NAMES.find(defined_frames[i])
		if idx < 0:
			printerr("Unexpected frame name: ", defined_frames[i])
			continue
		match VALID_FRAME_VECS[idx]:
			LEFT_VEC:
				views[LEFT_VEC] = get_view(i, false)
				views[RIGHT_VEC] = get_view(i, true)
			RIGHT_VEC:
				views[RIGHT_VEC] = get_view(i, false)
				views[LEFT_VEC] = get_view(i, true)
			FRONT_RIGHT_VEC:
				views[FRONT_LEFT_VEC] = get_view(i, false)
				views[FRONT_RIGHT_VEC] = get_view(i, true)
			FRONT_LEFT_VEC:
				views[FRONT_RIGHT_VEC] = get_view(i, false)
				views[FRONT_LEFT_VEC] = get_view(i, true)
			BACK_RIGHT_VEC:
				views[BACK_LEFT_VEC] = get_view(i, false)
				views[BACK_RIGHT_VEC] = get_view(i, true)
			BACK_LEFT_VEC:
				views[BACK_RIGHT_VEC] = get_view(i, false)
				views[BACK_LEFT_VEC] = get_view(i, true)
			var v:
				views[v] = get_view(i, false)
	yield(get_tree(), "idle_frame")
	if is_instance_valid(GameData.player):
		refresh_perspective(-GameData.player.global_transform.basis.z)

func get_view(i, flip_h):
	return [frames[i], # 0: texture
		width_in_meters/frames[i].get_width(), # 1: pixel size of main texture
		width_in_meters*frames[i].get_height()/float(frames[i].get_width())/2 + 0.011, # 2: y height of image
		flip_h, # 3: flip horizontally
		image_offsets[i], # 4: offset of the image
		]

func refresh_perspective(player_facing:Vector3 = -GameData.player.global_transform.basis.z):
	var best_dist = null
	var best_face
	var best_global_face
	for view_vec in views.keys():
		var my_facing = view_vec.rotated(Vector3.UP, global_transform.basis.get_euler().y)
		var dist = (my_facing - player_facing).length_squared()
		if best_dist == null or dist < best_dist:
			best_dist = dist
			best_face = view_vec
			best_global_face = my_facing
	if current_view_vec != best_face:
		current_view_vec = best_face
		var view = views[best_face]
		$Sprite3D.texture = view[0]
		$Sprite3D.pixel_size = view[1]
		$Sprite3D.transform.origin = view[4]
		$Sprite3D.transform.origin.y += view[2]
		$Sprite3D.flip_h = view[3]
		#$Sprite3D.global_transform.basis.z = -player_facing

