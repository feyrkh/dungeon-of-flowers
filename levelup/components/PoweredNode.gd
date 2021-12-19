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

func render_component():
	$Sprite.texture = load("res://img/levelup/node_"+stat_name+".png")

func _process(delta):
	if drain_protection > 0:
		drain_protection -= delta * 2
		return
	var energy_ratio = energy/max_energy
	energy = max(0, energy - (drain_speed * delta) * (1.01 - energy_ratio))
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
	if element != spark.element:
		if energy < spark.energy:
			energy = spark.energy - energy
			element = spark.element
			target_color = C.element_color(element)
		else:
			energy = max(0, energy - spark.energy)
	else:
		var energy_absorbed = min(min(1, spark.energy), max_energy-energy)
		if energy_absorbed > 0:
			energy = energy + energy_absorbed
			target_color = C.element_color(element)
		spark.energy -= energy_absorbed
		if energy >= max_energy:
			drain_protection = max(0, spark.energy)
	if energy > 0:
		set_process(true)
	#EventBus.emit_signal("grias_component_description", get_description())
