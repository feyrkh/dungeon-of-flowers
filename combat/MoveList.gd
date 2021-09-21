extends Node

var moves = {}
var unknownMove

func _ready():
	unknownMove = MoveData.new()
	add_move(Util.config(MoveData.new(), {
		"label": "Punch",
		"name": "punch",
		"type": "attack",
		"target": "enemy",
		"game_scene": "simpleLineGame",
		"game_config": {
			"base_damage": 3,
			"strikes": 3,
			"marker_move_speed": 1,
			"success_zones": [
				{"width": 0.05, "position": 0.25, "level": 1, "color": Color.green},
				{"width": 0.03, "position": 0.525, "level": 1.5, "color": Color.orange},
				{"width": 0.01, "position": 0.8, "level": 2, "color": Color.orangered}
			],
			"failure_level": 0.25
		}
	}))
	add_move(Util.config(MoveData.new(), {
		"label": "Headbutt",
		"name": "headbutt",
		"type": "attack",
		"target": "enemy",
		"game_scene": "simpleLineGame",
		"game_config": {
			"strikes": 1,
			"base_damage": 8,
			"marker_move_speed": 1,
			"success_zones": [
				{"width": 0.1, "position": 0.7, "level": 1, "color": Color.green},
				{"width": 0.05, "position": 0.7, "level": 1.5, "color": Color.orange},
				{"width": 0.02, "position": 0.7, "level": 2, "color": Color.orangered}
			],
			"failure_level": 0.25
		}
	}))
	add_move(Util.config(MoveData.new(), {
		"label": "Kick",
		"name": "kick",
		"type": "attack",
		"target": "enemy",
		"game_scene": "simpleLineGame",
		"game_config": {
			"base_damage": 10,
			"strikes": 1,
			"marker_move_speed": 1.5,
			"success_zones": [
				{"width": 0.05, "position": 0.8, "level": 2, "color": Color.orangered}
			],
			"failure_level": 0.5
		}
	}))

func get_move(name:String) -> MoveData:
	return moves.get(name, unknownMove)

func add_move(move:MoveData):
	if moves.has(move.name):
		printerr("Tried to create duplicate move: "+move.name)
		return
	moves[move.name] = move


#var label : String = "????"
#var name : String = "????"
#var hp_cost : int = 0
#var mp_cost : int = 0
#var base_damage : int = 1
#var base_heal_hp : int = 0
#var base_heal_mp : int = 0
#var damageFormat : String = "{player} hits {enemy} for {damage}!"
#var weakFormat : String = "{enemy} is barely scratched!"
#var strongFormat : String = "{enemy} is eviscerated!"
#var strikes : int = 1 # number of times the user can click to attack
#var strikeDelay : float = 0.05 # percentage of the strike zone you must traverse between strike attempts
#var marker_move_speed : float = 0.7 # percentage of the attack zone this moves per second; 1 means it will take 1 second, 0.5 means it will take 2 seconds
#var success_zones : Array = [
#	{"width":0.05, "position":0.5, "level":1, "color":Color.green},
#]

#var failure_level : float = 0.5 # base damage multiplier if the attacker doesn't strike, or misses

