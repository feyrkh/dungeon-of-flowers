extends DisableMovementTile

const STEPS_TO_REFILL = 5
var steps_until_refill = 0

func _ready():
	EventBus.connect("pre_save_game", self, "pre_save_game")
	EventBus.connect("finalize_load_game", self, "finalize_load_game")
	EventBus.connect("new_player_location", self, "new_player_location")

func pre_save_game():
	update_config({"steps_until_refill":steps_until_refill})

func finalize_load_game():
	render()

func render():
	$FilledSprite.visible = is_interactable()
	$EmptySprite.visible = !is_interactable()

func is_interactable():
	return steps_until_refill <= 0

func get_interactable_prompt():
	if is_interactable():
		return "Wash up"
	return null

func interact():
	steps_until_refill = STEPS_TO_REFILL
	render()
	EventBus.emit_signal("fountain_heal")
	EventBus.emit_signal("screen_flash", 1, Color.aquamarine)
	EventBus.emit_signal("refresh_interactables")

func new_player_location(map_x, map_y, rot_deg):
	steps_until_refill = max(0, steps_until_refill-1)
	render()
