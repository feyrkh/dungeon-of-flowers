extends Node

var enemies = {
	'furry': EnemyData.new("Furry Guy", 10, preload("res://img/monster1.jpg")),
	'brick': EnemyData.new("Brick", 20, preload("res://img/monster2.jpg")),
	'slime': EnemyData.new("Slime", 5, preload("res://art_exports/characters/enemy_puddle.png")),
	'ogre': EnemyData.new("Ogre", 15, preload("res://img/monster4.png")),
	'chinchilla': EnemyData.new("Flying Chinchilla", 10, preload("res://img/monster5.png")),
	'devil': EnemyData.new("The Devil", 15, preload("res://img/monster6.jpg")),
}

func get_enemy(enemy_id):
	var chosen
	if !(enemies.has(enemy_id)):
		chosen = enemies[enemies.keys()[randi() % enemies.keys().size()]]
	else:
		chosen = enemies[enemy_id]
	return EnemyData.new(chosen.label, chosen.max_hp, chosen.img)
