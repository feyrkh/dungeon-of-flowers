extends Reference
class_name CombatData

var targeted_enemy : EnemyData
var enemies : Array # of EnemyData
var allies : Array # of AllyData

func get_current_ally():
	return allies[0]

func get_targeted_enemy():
	return targeted_enemy

func set_targeted_enemy(enemy):
	self.targeted_enemy = enemy

func get_enemies():
	return enemies
