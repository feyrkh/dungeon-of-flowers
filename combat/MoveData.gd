extends Reference
class_name MoveData

const MINIGAMES = {
	"simpleLineGame": preload("res://minigame/SimpleLineGame.tscn"),
	"attackRing": preload("res://minigame/attackRing/AttackRingGame.tscn"),
	"stackingTower": preload("res://minigame/stackingTower/StackingTowerGame.tscn"),
}
const Enums = preload("res://Enums.gd")

var label : String = "????"
var name : String = "????"
var type : String = "attack" # attack, defend, skill, item
var target : String = "enemy" # enemy, all_enemies, random_enemy, ally, all_allies, self
var hp_cost : int = 0
var mp_cost : int = 0
var base_damage : int = 1
var base_heal_hp : int = 0
var base_heal_mp : int = 0
var game_scene: String
var game_config : Dictionary

func get_move_scene(source, target):
	var game_prefab = MINIGAMES.get(game_scene)
	if !game_prefab:
		printerr("Missing minigame scene: ", game_scene)
		game_prefab = MINIGAMES.get("simpleLineGame")
	var scene = game_prefab.instance()
	scene.set_minigame_config(game_config, source, target)
	return scene
