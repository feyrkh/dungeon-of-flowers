extends Control

onready var ShieldSizeLabel:Label = find_node("ShieldSizeLabel")
onready var ShieldSpeedLabel:Label = find_node("ShieldSpeedLabel")
onready var ShieldStrengthLabel:Label = find_node("ShieldStrengthLabel")

func _ready():
	visible = false

func refresh(all_shields):
	# see AllyData.update_shields() for format
	#	"shield_strength": config.get("shield_strength", 1),
	#	"shield_speed": config.get("shield_speed", 1),
	#	"shield_size": config.get("shield_size", 1),
	var shield_data = {}
	for shield in all_shields:
		shield_data["shield_size"] = max(shield.get("shield_size", 0), shield_data.get("shield_size", 0))
		shield_data["shield_speed"] = max(shield.get("shield_speed", 0), shield_data.get("shield_speed", 0))
		shield_data["shield_strength"] = shield.get("shield_strength", 0) - shield.get("shield_damage", 0) + shield_data.get("shield_strength", 0)
	ShieldSizeLabel.text = str(shield_data.get("shield_size", 0))
	ShieldSpeedLabel.text = str(shield_data.get("shield_speed", 0))
	ShieldStrengthLabel.text = str(shield_data.get("shield_strength", 0))
	visible = ShieldStrengthLabel.text != "0"
