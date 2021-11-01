extends Node2D

func _ready():
	CombatMgr.connect("add_ally_effect_bubble", self, "add_ally_effect_bubble")

func add_ally_effect_bubble(effect_bubble):
	add_child(effect_bubble)
