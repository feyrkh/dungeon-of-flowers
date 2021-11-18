extends DisableMovementTile
export var is_open = false setget set_is_open
var animating=false

func _ready():
	EventBus.connect("pre_save_game", self, "pre_save_game")
	EventBus.connect("finalize_load_game", self, "finalize_load_game")

func pre_save_game():
	if is_open:
		GameData.set_map_data(map_layer, map_position, is_open)
	else:
		GameData.set_map_data(map_layer, map_position, null)
		

func finalize_load_game():
	var save_data = GameData.get_map_data(map_layer, map_position)
	if save_data:
		#set_is_open(save_data)
		open(0)

func set_is_open(val):
	is_open = val
	disable_movement(!is_open)

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)
	set_is_open(is_open)

func is_interactable():
	return !animating

func get_interactable_prompt():
	if is_open: 
		return "Close Gate"
	else: 
		return "Open Gate"

func interact():
	var key_needed = map_config.get("key")
	if key_needed and !GameData.inventory.get(key_needed):
		locked()
	else:
		if is_open:
			close()
		else:
			open()
	EventBus.emit_signal("refresh_interactables")

func open(open_time=2):
	var tween:Tween = Util.one_shot_tween(self)
	tween.interpolate_property(self, "translation:y", 0, 3, open_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.start()
	animating = true
	is_open = true # set before tween finish in case they save partway through
	yield(tween, "tween_all_completed")
	animating = false
	set_is_open(true)
	EventBus.emit_signal("refresh_interactables")

func locked():
	var tween:Tween = Util.one_shot_tween(self)
	for i in range(1):	
		tween.interpolate_property(self, "transform:origin", transform.origin, transform.origin+transform.basis.z*0.05, 0.05, 0, 2, i*0.1)
		tween.interpolate_property(self, "transform:origin", transform.origin+transform.basis.z*0.05, transform.origin, 0.05, 0, 2, i*0.1+0.1)
	tween.start()
	animating = true
	yield(tween, "tween_all_completed")
	animating = false
	EventBus.emit_signal("refresh_interactables")
	if map_config.get("locked_chat") and GameData.get_state("lock_complaint", 0) < OS.get_system_time_secs():
		GameData.set_state("lock_complaint", OS.get_system_time_secs()+10)
		EventBus.emit_signal("start_chat", map_config.get("locked_chat"), ChatMgr.INTERRUPT_IF_BUSY)

func close():
	var tween:Tween = Util.one_shot_tween(self)
	var open_time = 2
	tween.interpolate_property(self, "translation:y", 3, 0, open_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()
	animating = true
	set_is_open(false)
	yield(tween, "tween_all_completed")
	animating = false
	EventBus.emit_signal("refresh_interactables")
