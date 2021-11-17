extends DisableMovementTile

var is_open

func _ready():
	pass

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)
	disable_movement()

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
	#tween.interpolate_property(self, "transform:origin", transform.origin, transform.origin+transform.basis.y, open_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	var delay = 0
	var segment_time = open_time/12.0
	var flex = 0.2
	tween.interpolate_property($PerspectiveSprite, "scale:x", 1.0, 1+flex, segment_time, 0, 2, delay)
	tween.interpolate_property($PerspectiveSprite, "scale:y", 1.0, 1-flex, segment_time, 0, 2, delay)
	delay += segment_time
	tween.interpolate_property($PerspectiveSprite, "scale:x", 1+flex, 1-flex, segment_time, 0, 2, delay)
	tween.interpolate_property($PerspectiveSprite, "scale:y", 1-flex, 1+flex, segment_time, 0, 2, delay)
	tween.interpolate_property(self, "transform:origin", transform.origin, transform.origin+transform.basis.y*0.3, segment_time, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)
	delay += segment_time
	tween.interpolate_property($PerspectiveSprite, "scale:x", 1-flex, 1.0, segment_time, 0, 2, delay)
	tween.interpolate_property($PerspectiveSprite, "scale:y", 1+flex, 1.0, segment_time, 0, 2, delay)
	tween.interpolate_property(self, "transform:origin", transform.origin+transform.basis.y*0.3, transform.origin, segment_time, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)
	delay += segment_time
	tween.start()
	is_open = true # set before tween finish in case they save partway through
	EventBus.emit_signal("refresh_interactables")
	yield(tween, "tween_all_completed")
	$PerspectiveSprite.visible = false
	$AnimatedSprite3D.visible = true
	$AnimatedSprite3D.play()
	yield($AnimatedSprite3D, "animation_finished")
	change_tile(-1)
	acquire_items()
	tween = Util.one_shot_tween(self)
	tween.interpolate_property(self, "modulate:a", 1.0, 0, 0.5, 0, 2, open_time - delay)
	tween.start()
	yield(tween, "tween_all_completed")
	EventBus.emit_signal("refresh_interactables")
	disable_movement(false)
	queue_free()

func acquire_items():
	var items = map_config.get("chest_items", [])
	var key = map_config.get("key", null)
	if key:
		items.append(key)
	for item in items:
		EventBus.emit_signal("acquire_item", item, 1)
