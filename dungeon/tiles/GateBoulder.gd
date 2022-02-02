# Map config:
# key: ID of the key that must be in your inventory
# locked_chat: chat ID to play if locked

extends DisableMovementTile

const CLOSE_POSITION = -3

export var is_open = false setget set_is_open
var animating=false
var minigame_grid_size = 8
var minigame_config = {}

func _ready():
	EventBus.connect("pre_save_game", self, "pre_save_game")
	EventBus.connect("finalize_load_game", self, "finalize_load_game")

func pre_save_game():
	GameData.set_map_data(map_layer, map_position, {"is_open":is_open, "minigame_config":minigame_config})

func finalize_load_game():
	if is_open:
		open(0)
	else:
		close(0)

func set_is_open(val):
	is_open = val
	disable_movement(!is_open)

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)
	if is_open:
		open(0)
	else:
		close(0)

func is_interactable():
	return !animating and !is_open

func get_interactable_prompt():
	if !is_open and GameData.inventory.get("pickaxe"):
		return "Break Boulder"
	return null

func interact():
	if GameData.inventory.get("pickaxe"):
		open_minigame()
	EventBus.emit_signal("refresh_interactables")

func open_minigame():
	var minigame = load("res://minigame/boulderBreak/BoulderBreakGame.tscn").instance()
	minigame.setup(self, minigame_grid_size)
	get_tree().root.find_node("FullScreenOverlayContainer", true, false).add_child(minigame)

func open(open_time=2):
	if open_time > 0:
		var tween:Tween = Util.one_shot_tween(self)
		tween.interpolate_property(self, "translation:y", 0, CLOSE_POSITION, open_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
		tween.start()
		animating = true
		is_open = true # set before tween finish in case they save partway through
		yield(tween, "tween_all_completed")
		animating = false
		set_is_open(true)
		EventBus.emit_signal("refresh_interactables")
	else:
		set_is_open(true)
		translation.y = CLOSE_POSITION

func close(open_time=2):
	if open_time > 0:
		var tween:Tween = Util.one_shot_tween(self)
		tween.interpolate_property(self, "translation:y", CLOSE_POSITION, 0, open_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.start()
		animating = true
		set_is_open(false)
		yield(tween, "tween_all_completed")
		animating = false
		EventBus.emit_signal("refresh_interactables")
	else:
		set_is_open(false)
		translation.y = 0
