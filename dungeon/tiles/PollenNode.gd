extends DisableMovementTile

onready var TileMetadata = find_node("TileMetadata", true, false)

var destroyed = false
var interact_dialogue = null
var interact_combat = null
var post_interact_dialogue = null

func on_map_place(dungeon, layer_name:String, cell:Vector2):
	.on_map_place(dungeon, layer_name, cell)
	disable_movement(!destroyed)

func is_interactable():
	return !destroyed

func get_interactable_prompt():
	return "Destroy"

func interact():
	if interact_dialogue:
		QuestMgr.play_cutscene(interact_dialogue)
		yield(QuestMgr, "cutscene_end")
	if interact_combat:
		CombatMgr.trigger_combat(interact_combat)
		yield(CombatMgr, "combat_end")
		yield(get_tree().create_timer(2.5), "timeout")
	if post_interact_dialogue:
		QuestMgr.play_cutscene(post_interact_dialogue)
		yield(QuestMgr, "cutscene_end")
	EventBus.emit_signal("refresh_interactables")
