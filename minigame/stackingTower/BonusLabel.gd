extends Node2D

const EARN_COLOR = Color.magenta

var bonus_type
var bonus_amt
var earned = false

func setup(_bonus_settings):
	bonus_type = _bonus_settings["type"]
	bonus_amt = _bonus_settings["amt"]
	$Label.text = get_label_desc()

func get_label_desc():
	match bonus_type:
		"shield_size": return "Shield Size +%.0f%%" % (bonus_amt*100)
		"shield_speed": return "Shield Speed +%.0f%%" % (bonus_amt*100)
		"shield_dash": return "Shield Dash"
		"shield_strength": return "Shield Durability +%d" % bonus_amt
		"bonus_shield": return "Bonus Shield"
		_: return bonus_type+" +"+str(bonus_amt)

func check_earned(tower_global_y):
	if tower_global_y < global_position.y:
		modulate = EARN_COLOR
		earned = true
	return earned
