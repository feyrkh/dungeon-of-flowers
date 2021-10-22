extends Node2D

var shields = []

func _ready():
	CombatMgr.connect("execute_combat_intentions", self, "_on_execute_combat_intentions")
	CombatMgr.connect("enemy_turn_complete", self, "_on_enemy_turn_complete")
	CombatMgr.connect("player_move_complete", self, "_on_player_move_complete")

func add_shield(ally, shield_data):
	var scene = load(shield_data.get("scene", "res://combat/ShieldHard.tscn")).instance()
	scene.setup(ally, shield_data)
	add_child(scene)
	shields.append(scene)

func _on_execute_combat_intentions(allies, enemies):
	render_shields(allies)

func _on_player_move_complete(combat_data):
	render_shields(combat_data.allies)

func render_shields(allies):
	for shield in shields:
		if is_instance_valid(shield):
			shield.queue_free()
	shields = []
	position = Vector2.ZERO
	for ally in allies:
		var shield_list = ally.get_shields()
		for shield_data in shield_list:
			add_shield(ally, shield_data)

func _on_enemy_turn_complete(_combat_data):
	for child in get_children():
		child.visible = false
		child.queue_free()
