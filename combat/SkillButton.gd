extends Button

signal skill_triggered(combat_data, move_data)

var combat_data:CombatData
var move_data:MoveData

func post_config(config):
	text = move_data.label

func _on_SkillButton_pressed():
	print("Clicked on skill: "+move_data.name)
	emit_signal("skill_triggered", combat_data, move_data)

func unhighlight():
	modulate = Color.white

func highlight():
	modulate = Color.green
