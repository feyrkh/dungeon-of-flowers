extends Control
class_name AllyPortraits


onready var Allies = [find_node("Ally1"), find_node("Ally2"), find_node("Ally3")]

func _ready():
	setup(GameData.allies)

func setup(ally_data):
	for i in range(ally_data.size()):
		if ally_data[i] == null:
			Allies[i].queue_free()
			Allies[i] = null
		else:
			Allies[i].setup(ally_data[i])

func combat_mode():
	for ally in Allies:
		ally.combat_mode()

func explore_mode():
	for ally in Allies:
		if ally:
			ally.explore_mode()

func update_labels():
	for ally in Allies:
		if ally:
			ally.update_labels()

func get_live_allies():
	var result = []
	for ally in Allies:
		if ally and ally.is_alive():
			result.append(ally)
	return result
