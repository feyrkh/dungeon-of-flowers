extends Reference
class_name CombatData

var ally : AllyData
var targeted_enemy : EnemyData
var enemies : Array

func get_current_ally():
	return ally

func get_targeted_enemy():
	return targeted_enemy

func set_targeted_enemy(enemy):
	self.targeted_enemy = enemy

func get_enemies():
	return enemies
