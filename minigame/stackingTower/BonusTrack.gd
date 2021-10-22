extends Node2D

const BonusLabel = preload("res://minigame/stackingTower/BonusLabel.tscn")

var track_bonuses
var block_height
var top_bonus_label_y = 0
var label_fib1 = 0
var label_fib2 = 0.75
var bonus_labels = []
var labels_printed = 0
var bonus_type

func update_label_tracks():
	for i in range(10):
		var new_fib = label_fib1 + label_fib2
		var new_y = top_bonus_label_y - new_fib*block_height
		if global_position.y - new_y > 0:
			label_fib1 = label_fib2
			label_fib2 = new_fib
			var new_label = BonusLabel.instance()
			add_child(new_label)
			bonus_labels.append(new_label)
			new_label.setup(track_bonuses[labels_printed])
			new_label.position = Vector2(0, new_y)
			labels_printed += 1
			if labels_printed >= track_bonuses.size():
				labels_printed = track_bonuses.size() - 1
		else:
			return
	
func setup(_bonus_type, _track_bonuses, _block_height):
	bonus_type = _bonus_type
	track_bonuses = _track_bonuses
	block_height = _block_height
	top_bonus_label_y = 0
	update_label_tracks()

func get_earned_bonuses():
	var bonuses = {}
	for bonus_label in bonus_labels:
		if bonus_label.earned:
			bonuses[bonus_label.bonus_type] = bonuses.get(bonus_label.bonus_type, 0) + bonus_label.bonus_amt
	return bonuses

func check_earned(tower_global_y):
	for label in bonus_labels:
		label.check_earned(tower_global_y)
