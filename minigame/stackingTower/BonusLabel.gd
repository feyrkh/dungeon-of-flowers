extends Node2D

const EARN_COLOR = Color.magenta

var bonus_type
var bonus_amt
var earned = false

func setup(_bonus_settings):
	bonus_type = _bonus_settings["type"]
	bonus_amt = _bonus_settings["amt"]
	$Label.text = get_label_desc()
	$Img.texture = load(get_label_img())
	visible = get_visibility()
	
func get_visibility():
	match bonus_type:
		"shield_size": return false
		"shield_speed": return false
		"shield_dash": return true
		"shield_strength": return false
		"bonus_shield": return true
		_: return false

func get_label_desc():
	match bonus_type:
		"shield_size": return "+%.0f%%" % (bonus_amt*100)
		"shield_speed": return "+%.0f%%" % (bonus_amt*100)
		"shield_dash": return ""
		"shield_strength": return "+%d" % bonus_amt
		"bonus_shield": return ""
		_: return bonus_type+" +"+str(bonus_amt)
		
func get_label_img():
	match bonus_type:
		"shield_size": return "res://art_exports/ui_battle/ui_tower_sizecounter.png"
		"shield_speed": return "res://art_exports/ui_battle/ui_tower_speedcounter.png"
		"shield_dash": return "res://art_exports/ui_battle/ui_tower_dashcounter.png"
		"shield_strength": return "res://art_exports/ui_battle/ui_tower_durabilitycounter.png"
		"bonus_shield": return "res://art_exports/ui_battle/ui_tower_shieldcounter.png"
		_: return "res://art_exports/ui_battle/ui_tower_shieldcounter.png"

func check_earned(tower_global_y):
	if tower_global_y < global_position.y:
		modulate = EARN_COLOR
		earned = true
	return earned
