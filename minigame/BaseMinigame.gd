extends Node
class_name BaseMinigame

var isSetup = false
var difficultyLevel:int = 0
var minigameConfig:Dictionary

func setupGame():
	randomize()
	isSetup = true
	
func getPowerText(powerLevel):
	match powerLevel:
		0: return "FUEL PUMP NOT PRIMED"
		1: return "FUEL PUMP OPERATING AT MINIMUM CAPACITY"
		2: return "FUEL PUMP OPERATING AT REDUCED CAPACITY"
		3: return "FUEL PUMP OPERATING AT FULL CAPACITY"

func setMinigameConfig(_config:Dictionary):
	minigameConfig = _config
	
func saveMinigameConfig():
	pass
