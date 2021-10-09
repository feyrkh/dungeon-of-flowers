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
		"game_scene": "attackRing",
		"game_config": {
			"damage": 20/3,
			"targets": [
				{"offset": 0.3, "hi": 2, "med": 20, "low": 25},
				{"offset": 0.6, "hi": 2, "med": 20, "low": 25},
				{"offset": 0.9, "hi": 2, "med": 20, "low": 25},
			]
		}
	}))
	add_move(Util.config(MoveData.new(), {
		"label": "Thump",
		"name": "thump",
		"type": "attack",
		"target": "enemy",
		"game_scene": "attackRing",
		"game_config": {
			"damage": 6,
			"targets": [
				{"offset": 0.8, "hi": 1, "med": 9, "low": 25},
			]
		}
	}))
	add_move(Util.config(MoveData.new(), {
		"label": "Slash",
		"name": "slash",
		"type": "attack",
		"target": "enemy",
		"game_scene": "attackRing",
		"game_config": {
			"damage": 20/2,
			"targets": [
				{"offset": 0.7, "hi": 5, "med": 15, "low": 20},
				{"offset": 0.8, "hi": 5, "med": 15, "low": 20},
			]
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

