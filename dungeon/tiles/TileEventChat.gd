# Meant to be used as a child of a TileEvent node
# Map config:
# event_dialogue: name of the Dialogic dialogue cutscene to play

extends Node

var event_chat # gets auto-filled by map config if it exists

func can_trigger_event(tile_event, map_config):
	return true

func trigger_event(tile_event, map_config):
	ChatMgr.start_chat(event_chat)
