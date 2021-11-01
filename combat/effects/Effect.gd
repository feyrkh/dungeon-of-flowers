extends Resource
class_name Effect

signal effect_complete(effect, source_data, source_node, target_data, target_node)

var source_data
var source_node
var target_data
var target_node
var effect_outlives_source = true

# source_data/target_data: AllyData/EnemyData or array of these
# source_node/target_node: AllyCombatDisplay/Enemy
func apply_effect(_source_data, _source_node, _target_data, _target_node):
	source_data = _source_data
	target_data = _target_data
	source_node = _source_node
	target_node = _target_node
	if source_data is Array:
		if !(source_node is Array) or (source_node.size() != source_data.size()):
			printerr("Incorrect array size for source_node ", source_node, "; expected same size as source_data", source_data)
			return
		if !(target_data is Array) or (target_data.size() != source_data.size()):
			printerr("Incorrect array size for target_data ", target_data, "; expected same size as source_data", source_data)
			return
		if !(target_node is Array) or (target_node.size() != source_data.size()):
			printerr("Incorrect array size for target_node ", target_node, "; expected same size as source_data", source_data)
			return
		for i in range(source_data.size()):
			apply_effect_single_target(source_data[i], source_node[i], target_data[i], target_node[i])
	else:
		apply_effect_single_target(source_data, source_node, target_data, target_node)

func apply_effect_single_target(source_data, source_node, target_data, target_node):
	print("Applying effect: ", get_effect_desc(), " to ", target_data.label)

func get_effect_desc():
	return self.get_class()
