extends Node

var moves = {}
var unknownMove

func _ready():
	unknownMove = MoveData.new()
	add_move(Util.config(MoveData.new(), {
		"label": "Punch",
		"name": "punch",
		"base_damage": 3,
		"damageFormat": "{player} pummels {enemy} for {damage} damage!",
		"weakFormat": "But {enemy} shrugs off the blows...",
		"strongFormat": "{enemy} reels from the punishing blows!",
		"strikes": 3,
		"markerMoveSpeed": 1,
		"successZones": [
			{"width": 0.05, "position": 0.25, "level": 1, "color": Color.green},
			{"width": 0.03, "position": 0.525, "level": 1.5, "color": Color.orange},
			{"width": 0.01, "position": 0.8, "level": 2, "color": Color.orangered}
		],
		"failureLevel": 0.25
	}))
	add_move(Util.config(MoveData.new(), {
		"label": "Headbutt",
		"name": "headbutt",
		"base_damage": 8,
		"damageFormat": "{player} headbutts {enemy} for {damage} damage!",
		"weakFormat": "But {enemy} just grins at {player}!",
		"strongFormat": "{enemy} is seeing stars!",
		"strikes": 1,
		"markerMoveSpeed": 1,
		"successZones": [
			{"width": 0.1, "position": 0.7, "level": 1, "color": Color.green},
			{"width": 0.05, "position": 0.7, "level": 1.5, "color": Color.orange},
			{"width": 0.02, "position": 0.7, "level": 2, "color": Color.orangered}
		],
		"failureLevel": 0.25
	}))
	add_move(Util.config(MoveData.new(), {
		"label": "Kick",
		"name": "kick",
		"base_damage": 10,
		"damageFormat": "{player} snaps a kick into {enemy} for {damage} damage!",
		"weakFormat": "But {enemy} knocks their leg away...",
		"strongFormat": "{enemy} staggers back!",
		"strikes": 1,
		"markerMoveSpeed": 1.5,
		"successZones": [
			{"width": 0.05, "position": 0.8, "level": 2, "color": Color.orangered}
		],
		"failureLevel": 0.5
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
#var markerMoveSpeed : float = 0.7 # percentage of the attack zone this moves per second; 1 means it will take 1 second, 0.5 means it will take 2 seconds
#var successZones : Array = [
#	{"width":0.05, "position":0.5, "level":1, "color":Color.green},
#]

#var failureLevel : float = 0.5 # base damage multiplier if the attacker doesn't strike, or misses

