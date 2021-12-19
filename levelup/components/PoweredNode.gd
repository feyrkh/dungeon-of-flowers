extends Node2D

const STATS = {
	"health": {
		"label": "Health Nexus",
		"desc": "An energy nexus connected to Grias' life force. Power it with elemental energy from a core to improve her survivability.",
		C.ELEMENT_SOIL: {"max_hp": 10},
		C.ELEMENT_WATER: {"max_hp": 5},
		C.ELEMENT_SUN: {"walk_regen": 0.1},
		C.ELEMENT_DECAY: {"max_hp": 20, "walk_regen": -0.05}
	}
}

var stat_name = "health"
var element = C.ELEMENT_ALL
var energy = 0
var max_energy = 1.0
var drain_speed = 0.05  # drained energy per second
var drain_protection = 0
var target_color = Color.white

func _ready():
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
	$Sprite.texture = load("res://img/levelup/node_"+stat_name+".png")

func _process(delta):
	if drain_protection > 0:
		drain_protection -= delta * 2
		return
	var energy_ratio = energy/max_energy
	energy = min(max_energy, max(0, energy - (drain_speed * delta) * (1.01 - energy_ratio)))
	$Sprite.modulate = lerp(Color.white, target_color, energy_ratio)
	if energy <= 0:
		set_process(false)

func get_component_label():
	var effect_desc = C.grias_stat_effects_desc(STATS[stat_name].get(element, null), energy)
	return STATS[stat_name]["label"] + "\n" + effect_desc

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
		energy_absorbed = min(min(1, spark.energy), max_energy-energy)
		if energy_absorbed > 0:
			energy = energy + energy_absorbed
			target_color = C.element_color(element)
		spark.energy -= max(energy_absorbed*2, 0.05)
		if energy >= max_energy:
			drain_protection = max(0, spark.energy)
	if energy_absorbed > 0:
		EventBus.emit_signal("grias_levelup_fail_clear_fog", tile_coords, spark.fog_clear_color)
	if energy > 0:
		set_process(true)
	#EventBus.emit_signal("grias_component_description", get_description())
