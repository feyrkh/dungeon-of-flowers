extends Node2D

# default shield for Grias if she doesn't have a defensive stance set up
const BASIC_SHIELD = {
	"pos": Vector2(0, -200),
	"shield_strength": 1,
	"shield_size": 0.5,
}

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
		if ally.data.label == "Grias" and shield_list.size() == 0 and GameData.inventory.get("shield"):
			shield_list.append(BASIC_SHIELD)
		for shield_data in shield_list:
			add_shield(ally, shield_data)

func _on_enemy_turn_complete(_combat_data):
	for child in get_children():
		child.visible = false
		child.queue_free()
