extends Effect
class_name EffectHeal

const EffectHealBubble = preload("res://combat/effects/EffectHealBubble.tscn")

var heal_amt
var regen_amt
var regen_rounds

# source_data/dest_data: AllyData/EnemyData or array of these
# source_node/dest_node: AllyCombatDisplay/Enemy
func apply_effect_single_target(source_data, source_node, target_data, target_node):
	var amt = round(heal_amt)
	CombatMgr.emit_signal("combat_animation", 1.0)
	# TODO: healing animation
	target_data.set_hp(min(target_data.max_hp, amt + target_data.hp))
	if regen_amt > 0:
		regen_rounds = max(1, regen_rounds)
		var regen_bubble = load("res://combat/effects/EffectHealBubble.tscn").instance()
		var regen_effect = load("res://combat/effects/EffectHeal.gd").new()
		regen_effect.heal_amt = regen_amt
		regen_bubble.effect_setup(self, source_data, source_node, target_data, target_node)
		regen_bubble.effect_timer = regen_rounds
		target_node.add_positive_effect_bubble(regen_bubble)
