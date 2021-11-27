extends DungeonEntity

const ArrowFlight = preload("res://dungeon/tiles/ArrowFlight.tscn")

var firing = true
var firing_interval = 5
var timer = 0

func pre_save_game():
	update_config({"firing":firing, "firing_interval":firing_interval, "timer":timer})

func _ready():
	pass

func _process(delta):
	if CombatMgr.is_in_combat: 
		return
	timer -= delta
	if timer <= 0:
		timer = firing_interval
		trigger_trap()

func trigger_trap():
	var arrow = ArrowFlight.instance()
	arrow.transform.basis = transform.basis
	arrow.transform.origin = transform.origin + transform.basis.z*2.95
	arrow.setup(map_config)
	dungeon.add_child(arrow)
