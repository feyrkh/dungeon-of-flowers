extends Node

const HALF_VECTOR = Vector2(0.5, 0.5)

const FACING_UP = 0
const FACING_RIGHT = 90
const FACING_DOWN = 180
const FACING_LEFT = 270

const FACINGS = [FACING_UP, FACING_RIGHT, FACING_DOWN, FACING_LEFT]

const ELEMENT_SOIL = 0
const ELEMENT_WATER = 1
const ELEMENT_SUN = 2
const ELEMENT_DECAY = 3
const ELEMENT_ALL = 4

const ELEMENT_IDS = [ELEMENT_SOIL, ELEMENT_WATER, ELEMENT_SUN, ELEMENT_DECAY]
const ELEMENT_NAME = ["soil", "water", "sun", "decay", "all"]

static func element_name(element_id):
	if element_id < 0 or element_id >= ELEMENT_NAME.size():
		return "element_"+element_id
	return ELEMENT_NAME[element_id]

static func element_image(element_id):
	return load("res://img/levelup/"+element_name(element_id)+"_egg.png")

static func element_color(element_name):
	match element_name:
		C.ELEMENT_ALL: return Color.white
		C.ELEMENT_WATER: return Color.aqua
		C.ELEMENT_SOIL: return Color.gray
		C.ELEMENT_SUN: return Color.yellow
		C.ELEMENT_DECAY: return Color.purple
		_: return Color.white

const MERIDIAN_DIR_NONE = 0
const MERIDIAN_DIR_1 = 1
const MERIDIAN_DIR_2a = 2
const MERIDIAN_DIR_2b = 3
const MERIDIAN_DIR_3 = 4
const MERIDIAN_DIR_4 = 5

const MERIDIAN_DIR_NAMES = ["undirected", "directing", "opposing", "diverting", "fanning", "distributing"]

static func meridian_dir_name(dir):
	return MERIDIAN_DIR_NAMES[dir]

const GRIAS_STAT_LABEL = {
	"max_hp": "Max HP+", # increase max HP by a flat amount
	# TODO: Implement
	"walk_regen": "Walk Regen", # regen HP per step
	"max_sp": "Max SP+", # increase max SP by a flat amount
	# TODO: Implement
	"heal_sp": "Heal SP+", # when healing SP, multiply the amount healed by this %
	# TODO: Implement
	"heal_hp": "Heal HP+", # when healing HP, multiply the amount healed by this %
	# TODO: Implement
	"damage": "Damage+", # when dealing damage, increase it by this %
	# TODO: Implement
	"critical_chance": "Crit Chance+", # increase size of critical areas by this %
	# TODO: Implement
	"critical_damage": "Crit Damage+", # when dealing critical damage, increase it by this %
	# TODO: Implement
	"damage_reduce": "Dmg Reduce", # when taking damage, reduce it by a flat amount
	# TODO: Implement
	"damage_avoid": "Dmg Avoid", # when taking damage, this % chance to avoid damage entirely
	# TODO: Implement
	"damage_absorb": "Dmg->SP Absorb", # when taking damage, this % is converted to SP
	# TODO: Implement
	"damage_reflect": "Dmg Reflect", # when taking damage, this % chance to reflect it back at the enemy
	# TODO: Implement
	"pollen_bonus": "Pollen Bonus", # when consuming pollen, increase pollen points by this %
	# TODO: Implement
	"slash:hits": "Slash: Hit+",
	# TODO: Implement
	"slash:damage": "Slash: Damage+",
	# TODO: Implement
	"slash:cost": "Slash: Cost-",
	# TODO: Implement
	"bodyguard:hits": "Bodyguard: Hit+",
	# TODO: Implement
	"bodyguard:speed": "Bodyguard: Speed+",
	# TODO: Implement
	"bodyguard:cost": "Bodyguard: Cost-",
}

const GRIAS_STAT_FORMAT = {
	"max_hp": "%.0f HP",
	"walk_regen": "%.2f HP/step",
	"max_sp": "%.0f SP",
	"heal_sp": "%.1f%%",
	"heal_hp": "%.1f%%",
	"damage": "%.1f%%",
	"critical_chance": "%.1f%%",
	"critical_damage": "%.1f%%",
	"damage_reduce": "%.1f",
	"damage_avoid": "%.1f%%",
	"damage_absorb": "%.1f%%",
	"damage_reflect": "%.1f%%",
	"slash:hits": "%.0f Hit",
	"slash:damage": "%.1f HP",
	"slash:cost": "%.0f SP",
	"bodyguard:hits": "%d%% Toughness",
	"bodyguard:speed": "+%d%% Speed",
	"bodyguard:cost": "%d SP",
}

func grias_stat_effects_desc(effect_map, energy):
	if !effect_map:
		return ""
	var desc:PoolStringArray = PoolStringArray()
	var effects:Array = effect_map.keys()
	for effect_name in effects:
		desc.append("%s: %.1f" % [GRIAS_STAT_LABEL[effect_name], effect_map[effect_name] * energy])
	return desc.join("\n")
