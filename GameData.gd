extends Node

var allies = []
var world_tile_position = Vector2()
var facing = "north"

func _ready():
	EventBus.connect("new_player_location", self, "on_new_player_location")

func on_new_player_location(x, y, rot_deg):
	world_tile_position = Vector2(x, y)
	match int(round(rot_deg)):
		0: facing = "north"
		-90: facing = "east"
		180,-180: facing = "south"
		90: facing = "west"
		_: printerr("Unknown facing with angle ", int(round(rot_deg)))
