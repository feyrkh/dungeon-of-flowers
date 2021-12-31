# Meant to be used as a child of a TileEvent node
# Map config:
# event_combat: Name of the combat config to run, after any event_dialogue is finished
extends Node

var event_dialogue # gets auto-filled by map config if it exists
var event_combat # gets auto-filled by map config if it exists

func setup(tile_event, map_config) -> void:
	if event_dialogue:
		QuestMgr.connect("cutscene_end", self, "cutscene_end")

func cutscene_end(cutscene_name):
	if owner.player_on_tile and event_dialogue:
		trigger_combat()

func trigger_combat():
	CombatMgr.trigger_combat(event_combat)

func can_trigger_event(tile_event, map_config):
	return event_dialogue == null

func trigger_event(tile_event, map_config):
	trigger_combat()
