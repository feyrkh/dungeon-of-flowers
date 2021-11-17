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
	tween.interpolate_property(self, "transform:origin", transform.origin, transform.origin+transform.basis.y, open_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.start()
	is_open = true # set before tween finish in case they save partway through
	EventBus.emit_signal("refresh_interactables")
	yield(tween, "tween_all_completed")
	change_tile(-1)
	disable_movement(false)
	acquire_items()
	is_open = true
	EventBus.emit_signal("refresh_interactables")
	queue_free()

func acquire_items():
	var items = map_config.get("chest_items", [])
	var key = map_config.get("key", null)
	if key:
		items.append(key)
	for item in items:
		EventBus.emit_signal("acquire_item", item, 1)
