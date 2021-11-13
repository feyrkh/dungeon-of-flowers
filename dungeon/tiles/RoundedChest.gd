extends DisableMovementTile

var is_open

func _ready():
	EventBus.connect("player_start_move", self, "update_faces")
	EventBus.connect("player_finish_turn", self, "update_faces")

func update_faces():
	#var player_pos = GameData.player.global_transform.origin
	var player_rotation = GameData.player.global_transform.basis.z
	var best_dist = null
	var best_face
	for child in get_children():
		child.visible = false
		#var dist:float = child.global_transform.origin.distance_squared_to(player_pos)
		var dist = (child.global_transform.basis.z - player_rotation).length_squared()
		if best_dist == null or dist < best_dist:
			if best_face: best_face.visible = false
			best_dist = dist
			best_face = child
			best_face.visible = true
	

func is_interactable():
	return !is_open

func get_interactable_prompt():
	if !is_open: 
		return "Open Chest"
	else: 
		return ""

func interact():
	if !is_open:
		open()
	EventBus.emit_signal("refresh_interactables")

func open(open_time=2):
	var tween:Tween = Util.one_shot_tween(self)
	tween.interpolate_property(find_node("Lid"), "translation:z", 0, -5, open_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.start()
	is_open = true # set before tween finish in case they save partway through
	EventBus.emit_signal("refresh_interactables")
	yield(tween, "tween_all_completed")
	is_open = true
	tween.queue_free()
	EventBus.emit_signal("refresh_interactables")
