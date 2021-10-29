extends Node

var moves = {}
var unknownMove

func _ready():
	unknownMove = MoveData.new()
	EventBus.connect("pre_new_game", self, "on_pre_new_game")
	EventBus.connect("pre_save_game", self, "on_pre_save_game")
	EventBus.connect("post_load_game", self, "on_post_load_game")

func on_pre_new_game():
	pass

func on_pre_save_game():
	GameData.set_state("__MoveList", moves)

func on_post_load_game():
	moves = GameData.get_state("__MoveList", moves)

func get_move(name:String) -> MoveData:
	var move_data = moves.get(name)
	if !move_data:
		var move_json = DialogicResources.load_json("res://data/move/"+name+".json")
		if move_json.size() == 0:
			move_data = unknownMove
		else:
			move_data = MoveData.new()
			Util.config(move_data, move_json)
	return move_data

func add_move(move:MoveData):
	if moves.has(move.name):
		printerr("Tried to create duplicate move: "+move.name)
		return
	moves[move.name] = move


#var label : String = "????"
#var name : String = "????"
#var hp_cost : int = 0
#var sp_cost : int = 0
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

