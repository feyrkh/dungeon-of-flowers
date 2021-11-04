extends Reference
class_name CombatData

var enemies : Array # of EnemyData
var allies : Array # of AllyData
var rewards : Dictionary # ItemId -> count; ex: {"pollen_sun": 1, "pollen_water": 3, "pollen_soil": 1, "heal_potion": 1}

func get_enemies():
	return enemies

func load_from(file_name:String):
	if !file_name.begins_with("res:"):
		file_name = "res://data/encounter/"+file_name+".json"
	var data = DialogicResources.load_json(file_name)
	for enemy in data.get("enemies", []):
		if enemy is Array:
			enemy = enemy[rand_range(0, enemy.size())]
		if enemy == null:
			continue
		var new_enemy_data = EnemyData.new()
		new_enemy_data.load_from(enemy)
		enemies.append(new_enemy_data)
