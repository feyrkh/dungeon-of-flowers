extends DisableMovementTile

var is_open

func _ready():
	pass

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
