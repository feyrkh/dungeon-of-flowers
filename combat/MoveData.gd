extends Reference
class_name MoveData

var label : String = "????"
var name : String = "????"
var hp_cost : int = 0
var mp_cost : int = 0
var base_damage : int = 1
var base_heal_hp : int = 0
var base_heal_mp : int = 0
var damageFormat : String = "{player} hits {enemy} with a mysterious move for {damage}!"
var weakFormat : String = "{enemy} is barely scratched!"
var strongFormat : String = "{enemy} is eviscerated!"
var strikes : int = 1 # number of times the user can click to attack
var strikeDelay : float = 0.01 # number of seconds between strike attempts
var markerMoveSpeed : float = 0.7 # percentage of the attack zone this moves per second; 1 means it will take 1 second, 0.5 means it will take 2 seconds
var successZones : Array = [
	{"width":0.05, "position":0.5, "level":1, "color":Color.green},
]
#			"successZones": [
#				{"width": 0.05, "position": 0.25, "level": 1, "color": Color.green},
#				{"width": 0.03, "position": 0.525, "level": 1.5, "color": Color.orange},
#				{"width": 0.01, "position": 0.8, "level": 2, "color": Color.orangered}
#			],
var failureLevel : float = 0.5 # base damage multiplier if the attacker doesn't strike, or misses
var targets_enemy : bool = true
var targets_all_enemies : bool = false
var targets_ally : bool = false
