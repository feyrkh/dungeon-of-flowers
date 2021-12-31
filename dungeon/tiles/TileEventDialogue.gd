# Meant to be used as a child of a TileEvent node
# Map config:
# event_dialogue: name of the Dialogic dialogue cutscene to play

extends Node

var event_dialogue # gets auto-filled by map config if it exists

func can_trigger_event(tile_event, map_config):
	return true

func trigger_event(tile_event, map_config):
	var dialogue = event_dialogue
	QuestMgr.play_cutscene(dialogue)
