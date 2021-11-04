extends Effect
class_name EffectShield

var shield_data:Dictionary

# source_data/dest_data: AllyData/EnemyData or array of these
# source_node/dest_node: AllyCombatDisplay/Enemy
func apply_effect_single_target(source_data, source_node, target_data, target_node):
	target_data.update_shields(shield_data)
