extends Button

signal skill_triggered(combatData, moveData)

var combatData:CombatData
var moveData:MoveData

func post_config(config):
	text = moveData.label

func _on_SkillButton_pressed():
	print("Clicked on skill: "+moveData.name)
	emit_signal("skill_triggered", combatData, moveData)

func unhighlight():
	modulate = Color.white

func highlight():
	modulate = Color.green
