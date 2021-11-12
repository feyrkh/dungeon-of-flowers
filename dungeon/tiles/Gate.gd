extends Spatial

export var is_open = false setget set_is_open
var map_position:Vector2
var map_layer:String
var animating=false

func set_is_open(val):
	is_open = val
	var dungeon = GameData.dungeon
	if dungeon.has_method("get_tile_scene"):
		var corridor = dungeon.get_tile_scene("ground", map_position)
		var metadata:TileMetadata = corridor.find_node("TileMetadata")
		metadata.can_move_onto = is_open
	else:
		printerr("Couldn't find the dungeon scene while setting door open state!")

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	self.map_position = cell
	self.map_layer = layer_name
	set_is_open(is_open)

func is_interactable():
	return !animating

func get_interactable_prompt():
	if is_open: 
		return "Close Gate"
	else: 
		return "Open Gate"

func interact():
	if is_open:
		close()
	else:
		open()

func open():
	var tween:Tween = Util.one_shot_tween(self)
	var open_time = 2
	tween.interpolate_property(self, "translation:y", 0, 6, open_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.start()
	animating = true
	yield(tween, "tween_all_completed")
	animating = false
	set_is_open(true)
	tween.queue_free()
	EventBus.emit_signal("refresh_interactables")

func close():
	var tween:Tween = Util.one_shot_tween(self)
	var open_time = 2
	tween.interpolate_property(self, "translation:y", 6, 0, open_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()
	animating = true
	set_is_open(false)
	yield(tween, "tween_all_completed")
	animating = false
	tween.queue_free()
	EventBus.emit_signal("refresh_interactables")
