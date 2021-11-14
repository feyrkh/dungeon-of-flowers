extends Node

const dirs = [Vector2.ZERO, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
const INFEST_CHANCE_BASE = 0.2
const INFEST_CHANCE_MODIFIER = 0.05
const MOVE_CHANCE_BASE = 0.7
const MOVE_CHANCE_MODIFIER = 0.1

var pulses = []
var timer:Timer

func _ready():
	EventBus.connect("spawn_pollen", self, "add_pulse")
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = false
	timer.start(0.5)
	timer.connect("timeout", self, "process_pulse")

func add_pulse(coords:Vector2):
	if !QuestMgr.pollen_spread_enabled:
		print("pollen spawn disabled, not spawning pollen at ", coords)
		return
	print("spawning pollen at ", coords)
	pulses.append(coords)

func process_pulse():
	if !QuestMgr.pollen_spread_enabled:
		return
	if pulses.size() == 0:
		return
	var active_pulse = pulses.pop_front()
	var spread_dirs = []
	for dir in dirs:
		var spread_dir = active_pulse+dir
		if owner.can_pollen_spread(spread_dir):
			spread_dirs.append(spread_dir)
	spread_dirs.sort_custom(self, "sort_ascending")
	for spread_dir in spread_dirs:
		var pollen_level = owner.get_pollen_level(spread_dir)
		var infest_chance = INFEST_CHANCE_BASE - pollen_level*INFEST_CHANCE_MODIFIER
		if pollen_level == 0:
			infest_chance = 1.0
		elif pollen_level == 4:
			infest_chance = 0.05
		if randf() < infest_chance and spread_dir != active_pulse:
			owner.pollen_infest(spread_dir, pollen_level)
			return
		var move_chance = MOVE_CHANCE_BASE - pollen_level*MOVE_CHANCE_MODIFIER
		if randf() < move_chance:
			pulses.append(spread_dir)
			return
	pulses.append(active_pulse)

func sort_ascending(a, b):
	if owner.get_pollen_level(a) < owner.get_pollen_level(b):
		return true
	return false

	
