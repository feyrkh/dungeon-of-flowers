extends Control
class_name AllyPortraits

onready var Allies = [find_node("Ally1"), find_node("Ally2"), find_node("Ally3")]

func setup(ally_data1, ally_data2, ally_data3):
	Allies[0].setup(ally_data1)
	Allies[1].setup(ally_data2)
	Allies[2].setup(ally_data3)

func combat_mode():
	for ally in Allies:
		ally.combat_mode()

func explore_mode():
	for ally in Allies:
		ally.explore_mode()

func update_labels():
	for ally in Allies:
		ally.update_labels()
