extends DisableMovementTile

onready var TileMetadata = find_node("TileMetadata", true, false)

var destroyed = false
var interact_dialogue = null
var interact_combat = null
var post_interact_dialogue = null

func post_config(map_config):
	if destroyed:
		queue_free()

func pre_save_game():
	update_config({"destroyed":destroyed})

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
		#yield(get_tree().create_timer(2.5), "timeout")
	var floor_vines = GameData.dungeon.get_tile_scene("floor_overlay", map_position)
	if floor_vines and floor_vines.has_method("destroy_vines"):
		floor_vines.destroy_vines()
	if post_interact_dialogue:
		QuestMgr.play_cutscene(post_interact_dialogue)
		yield(QuestMgr, "cutscene_end")
		queue_free()
	queue_free()
	change_tile(-1)
	disable_movement(false)
	EventBus.emit_signal("refresh_interactables")

func destroy_vines():
	pass
