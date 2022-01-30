extends Reference
class_name StatValue

signal value_changed(old_val, new_val)

const EMPTY = {}
var value = 0 setget set_value, get_value
var max_value = 0 setget set_max_value, get_max_value
var effects = {} #{{"bonus_max":{"levelup":10}, "bonus_max_percent":...}
var can_go_below_zero = false

func _to_config() -> Dictionary:
	return {"value":value, "max_value":max_value, "effects":effects}

func _from_config(c):
	if c == null:
		return
	value = c.get("value", 0)
	max_value = c.get("max_value", 0)
	effects = c.get("effects", {})

func set_value(val, skip_eventing=false):
	if val < 0 and !can_go_below_zero:
		val = 0
	var old_val = value
	value = val
	if !skip_eventing and old_val != val:
		emit_signal("value_changed", old_val, val)

func get_value():
	return value

func set_max_value(val):
	max_value = val

func get_max_value():
	var effect_values = 0
	var effect_percents = 1.0
	var value_bonuses = effects.get("bonus_max_value", EMPTY)
	var pct_bonuses = effects.get("bonus_max_percent", EMPTY)
	for k in value_bonuses:
		effect_values += value_bonuses[k]
	for k in pct_bonuses:
		effect_percents *= pct_bonuses[k]
	return (max_value + effect_values) * effect_percents

func get_max_value_ratio(should_clamp=true):
	if value == 0:
		return 0
	if should_clamp:
		return clamp(value/get_max_value(), 0, 1)
	else:
		return value / get_max_value()

func bonus_max_value_effect(effect_name, bonus_amount):
	_update_max_effect(effect_name, "bonus_max_value", bonus_amount)

func bonus_max_percent_effect(effect_name, bonus_amount):
	_update_max_effect(effect_name, "bonus_max_percent", bonus_amount)

func _update_max_effect(effect_name, bonus_type, bonus_amount):
	var active_effects = effects.get(bonus_type, {})
	var prev_max = get_max_value()
	if bonus_amount == null or bonus_amount == 0:
		active_effects.erase(effect_name)
	else:
		active_effects[effect_name] = bonus_amount
	effects[bonus_type] = active_effects
	var new_max = float(get_max_value())
	var change_ratio = new_max/prev_max
	value = value * change_ratio

