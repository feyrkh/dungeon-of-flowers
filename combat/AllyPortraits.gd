extends Control
class_name AllyPortraits


onready var Allies = [find_node("Ally1"), find_node("Ally2"), find_node("Ally3")]

func _ready():
	setup(GameData.allies)

func setup(ally_data):
	for i in range(ally_data.size()):
		Allies[i].setup(ally_data[i])

func combat_mode():
	for ally in Allies:
		ally.combat_mode()

func explore_mode():
	for ally in Allies:
		ally.explore_mode()

func update_labels():
	for ally in Allies:
		ally.update_labels()
