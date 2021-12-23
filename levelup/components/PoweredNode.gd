extends Node2D

const DIRS = {
	Vector2.UP: C.FACING_DOWN,
	Vector2.DOWN: C.FACING_UP,
	Vector2.LEFT: C.FACING_RIGHT,
	Vector2.RIGHT: C.FACING_LEFT,
}

const STATS = {
	"health": {
		"label": "Health Nexus",
		"icon": "health",
		"desc": "An energy nexus connected to Grias' life force. Power it with elemental energy to improve her survivability.",
		C.ELEMENT_SOIL: {"max_hp": 10},
		C.ELEMENT_WATER: {"max_hp": 5},
		C.ELEMENT_SUN: {"walk_regen": 0.1},
		C.ELEMENT_DECAY: {"max_hp": 30, "walk_regen": -0.1}
	},
	"sp": {
		"label": "SP Nexus",
		"icon": "skill",
		"desc": "An energy nexus connected to Grias' stamina and skill. Power it with elemental energy to improve her ability to use special skills.",
		C.ELEMENT_SOIL: {"max_sp": 5},
		C.ELEMENT_WATER: {"heal_sp": 1},
		C.ELEMENT_SUN: {"max_sp": 10},
		C.ELEMENT_DECAY: {"max_sp": 20, "sp_heal": -1},
	},
	"attack": {
		"label": "Attack Nexus",
		"icon": "attack",
		"desc": "An energy nexus connected to Grias' muscles and coordination. Power it with elemental energy to improve her damage output.",
		C.ELEMENT_SOIL: {"damage": 10},
		C.ELEMENT_WATER: {"critical_chance": 2},
		C.ELEMENT_SUN: {"critical_damage": 20},
		C.ELEMENT_DECAY: {"damage": 20, "critical_damage": 20, "critical_chance": -5},
	},
	"defense": {
		"label": "Defense Nexus",
		"icon": "armor",
		"desc": "An energy nexus connected to Grias' sturdiness and reflexes. Power it with elemental energy to improve her defense.",
		C.ELEMENT_SOIL: {"damage_reduce": 1},
		C.ELEMENT_WATER: {"damage_avoid": 0.2},
		C.ELEMENT_SUN: {"damage_absorb": 5},
		C.ELEMENT_DECAY: {"damage_reflect": 1, "damage_reduce": -1},
	},
	"efficiency": {
		"label": "Efficiency Nexus",
		"icon": "efficiency",
		"desc": "An energy nexus connected to Grias' economy of action. Power it with elemental energy to improve how efficiently she uses energy.",
		C.ELEMENT_SOIL: {"heal_hp": 5},
		C.ELEMENT_WATER: {"heal_sp": 5},
		C.ELEMENT_SUN: {"pollen_bonus": 10},
		C.ELEMENT_DECAY: {"pollen_bonus": 25, "heal_hp": -5, "heal_sp": -5},
	},
}

var stat_name = "health"
var element = C.ELEMENT_ALL
var energy = 0
var max_energy = 1.0 setget set_max_energy, get_max_energy
var drain_speed = 0.05  # drained energy per second
var drain_protection = 0
var target_color = Color.white
var _focus_power_cache = null

var tilemap_mgr:TilemapMgr
var map_coords

func set_max_energy(val):
	max_energy = val

func get_max_energy():
	return max_energy + get_focus_power()

func setup(_tilemap_mgr, _map_coords):
	self.tilemap_mgr = _tilemap_mgr
	self.map_coords = _map_coords

func _ready():
	EventBus.connect("grias_reset_focus_power_cache", self, "reset_focus_power_cache")
	render_component()
	add_to_group("grias_bonus_provider")

func get_grias_bonus():
	if energy <= 0:
		energy = 0
	var bonuses = STATS.get(stat_name, {}).get(element, {}).duplicate()
	for k in bonuses.keys():
		bonuses[k] = bonuses[k] * energy
	return bonuses

func render_component():
	$Sprite.texture = load("res://img/levelup/node_"+STATS[stat_name].get("icon", stat_name)+".png")

func _process(delta):
	if drain_protection > 0:
		drain_protection -= delta * 2
		return
	var energy_ratio = energy/get_max_energy()
	if energy_ratio > 1.0:
		energy_ratio = 0.99
	energy = max(0, energy - (drain_speed * delta) * (1.01 - energy_ratio))
	$Sprite.modulate = lerp(Color.white, target_color, energy_ratio)
	if energy <= 0:
		element = C.ELEMENT_ALL
		set_process(false)

func get_component_label():
	var effect_desc = C.grias_stat_effects_desc(STATS[stat_name].get(element, null), energy)
	var bonus_desc = ""
	if get_focus_power() > 0:
		bonus_desc = " (+"+str(round(get_focus_power()*100))+"%)"
	return STATS[stat_name]["label"] + bonus_desc + "\n" + effect_desc

func get_description():
	return STATS[stat_name]["desc"]

func get_component_menu_items():
	EventBus.emit_signal("grias_component_description", get_description())
	# TODO: max energy increase, energy decay reduction
	return []

func spark_arrived(spark, tile_coords):
	var energy_absorbed = 0
	if element != spark.element:
		energy_absorbed = min(1, spark.energy)
		if energy < energy_absorbed:
			energy = energy_absorbed - energy
			element = spark.element
			target_color = C.element_color(element)
		else:
			energy = max(0, energy - energy_absorbed)
	else:
		energy_absorbed = min(min(1, spark.energy), get_max_energy()-energy)
		if energy_absorbed > 0:
			energy = energy + energy_absorbed
			target_color = C.element_color(element)
		spark.energy -= max(energy_absorbed*2, 0.05)
		if energy >= get_max_energy():
			drain_protection = max(0, spark.energy)
	if energy_absorbed > 0:
		EventBus.emit_signal("grias_levelup_fail_clear_fog", tile_coords, spark.fog_clear_color)
	if energy > 0:
		set_process(true)
	#EventBus.emit_signal("grias_component_description", get_description())

func get_focus_power():
	if _focus_power_cache == null:
		calculate_focus_power()
	return _focus_power_cache

func reset_focus_power_cache():
	_focus_power_cache = null

func calculate_focus_power():
	_focus_power_cache = 0.0
	for dir in DIRS:
		var possible_focus = tilemap_mgr.get_tile_scene("component", map_coords + dir)
		if possible_focus and possible_focus.has_method("get_focus_power") and possible_focus.get("facing") != null:
			var opposite_dir = DIRS[dir]
			if possible_focus.facing != opposite_dir:
				continue # not facing me so I don't get any focus benefit
			_focus_power_cache += possible_focus.get_focus_power()
