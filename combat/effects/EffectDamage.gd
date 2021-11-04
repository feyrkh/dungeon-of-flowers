extends Effect
class_name EffectDamage

var damage_amt

# source_data/dest_data: AllyData/EnemyData or array of these
# source_node/dest_node: AllyCombatDisplay/Enemy
func apply_effect_single_target(source_data, source_node, target_data, target_node):
	var amt = round(damage_amt)
	target_node.find_node("DamageIndicator").take_damage(damage_amt)
