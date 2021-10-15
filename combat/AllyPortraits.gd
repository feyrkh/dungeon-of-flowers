extends Control
class_name AllyPortraits

signal target_cancelled()
signal self_target_complete(target_ally, move_data)

const TargetMarker = preload("res://combat/TargetMarker.tscn")

onready var Allies = [find_node("Ally1"), find_node("Ally2"), find_node("Ally3")]
onready var TargetIcons = find_node("TargetIcons")

var active_move_data
var active_target_type
var active_target_idx

func _ready():
	set_process(false)
	setup(GameData.allies)
	for ally in Allies:
		var marker = TargetMarker.instance()
		TargetIcons.add_child(marker)
		marker.visible = false
		if ally != null:
			marker.rect_position = ally.rect_position + Vector2(ally.rect_size.x/2, -30)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		stop_targeting()
		emit_signal("target_cancelled")
	if active_target_type == "self":
		process_self_target_input()

func process_self_target_input():
	if Input.is_action_just_pressed("ui_accept"):
		stop_targeting()
		emit_signal("self_target_complete", Allies[active_target_idx], active_move_data)
		
func setup(ally_data):
	for i in range(ally_data.size()):
		if ally_data[i] == null:
			Allies[i].queue_free()
			Allies[i] = null
		else:
			Allies[i].setup(ally_data[i])

func combat_mode():
	for ally in Allies:
		ally.combat_mode()

func explore_mode():
	for ally in Allies:
		if ally:
			ally.explore_mode()

func update_labels():
	for ally in Allies:
		if ally:
			ally.update_labels()

func get_live_allies():
	var result = []
	for ally in Allies:
		if ally and ally.is_alive():
			result.append(ally)
	return result

func start_targeting(_active_move_data, cur_ally):
	match _active_move_data.target:
		"enemy": return # do nothing, AllyPortraits class doesn't care about enemy targeting
		"all_enemies":  return # do nothing, AllyPortraits class doesn't care about enemy targeting
		"random_enemy": return # do nothing, AllyPortraits class doesn't care about enemy targeting
		"ally": printerr("targeting mode not implemented: ally")
		"all_allies":  printerr("targeting mode not implemented: all_allies")
		"self": target_self(_active_move_data, cur_ally)
		_: 
			printerr(active_target_type+" unexpected move target type")
			return
	self.active_move_data = _active_move_data
	active_target_type = active_move_data.target
	set_process(true)

func stop_targeting():
	set_process(false)
	for icon in TargetIcons.get_children():
		icon.visible = false

func target_self(_active_move_data, cur_ally):
	active_target_idx = Allies.find(cur_ally)
	target_ally_by_idx(active_target_idx)

func target_ally_by_idx(ally_idx):
	var old_target_icon
	for icon in TargetIcons.get_children():
		icon.visible = false
	TargetIcons.get_child(ally_idx).visible = true 
	
