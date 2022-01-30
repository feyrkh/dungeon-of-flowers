extends Control

onready var AllyPortrait:AllyPortrait = find_node("AllyPortrait")

const POSITIVE_BUBBLE_HEIGHT = -50

onready var CurrentMoveLabel:Label = find_node("CurrentMoveLabel")
onready var FadeContainer:Control = find_node("FadeContainer")
onready var CombatIcons = find_node("CombatIcons")
onready var Submenu = find_node("Submenu")
onready var default_position = rect_position
onready var selected_position = rect_position - Vector2(0, 20)
onready var exhausted_position = rect_position - Vector2(0, -20)
onready var category_zoom_icons = [find_node("IconZoomFight"), find_node("IconZoomSkill"), find_node("IconZoomDefend"), find_node("IconZoomItem")]
onready var TargetArea:Position2D = find_node("TargetArea")
onready var DamageIndicator = find_node("DamageIndicator")
onready var HpDamageOrigin = find_node("HpDamageOrigin")
onready var SpDamageOrigin = find_node("SpDamageOrigin")

export(Color) var selected_color = Color.white
export(Color) var deselected_color = Color(0.9, 0.9, 0.9)
export(Color) var exhausted_color = Color(0.7, 0.7, 0.7)

var data:AllyData
var last_category_idx
var move_lists = ["attack", "skill", "defend", "item", ]
var exhausted = false

func setup(_data:AllyData):
	self.data = _data
	AllyPortrait.setup(data)
	if !data:
		return
	AllyPortrait.update_labels()
	CombatIcons.setup(data)
	_data.connect("ally_sp_lost", self, "ally_sp_lost")

func _ready():
	CombatIcons.categories.append(find_node("IconStatus"))
	CombatMgr.connect("player_turn_complete", self, "_on_CombatScreen_player_turn_complete")
	CombatMgr.connect("start_enemy_turn", self, "_on_CombatScreen_start_enemy_turn")
	CombatMgr.connect("start_player_turn", self, "_on_CombatScreen_start_player_turn")
	CombatMgr.connect("enemy_move_complete", self, "_on_enemy_move_complete")
	EventBus.connect("damage_all_allies", self, "_on_damage_all_allies")

func get_shields():
	return data.get_shields()

func get_target(target_scatter = 0):
	var half_size = 180
	var target = TargetArea.global_position
	if target_scatter > 0:
		target.x += (half_size*2*randf() - half_size)*target_scatter
	return target

func combat_mode():
	FadeContainer.modulate = selected_color
	rect_position = default_position

func explore_mode():
	AllyPortrait.deselect()
	modulate = selected_color
	FadeContainer.modulate = selected_color
	rect_position = default_position
	find_node("IconStatus").visible = false

func disable_combat_features():
	find_node("BulletStrikeArea").queue_free()

func is_alive():
	return data.hp.value > 0.01

func deselect():
	AllyPortrait.deselect()
	CombatIcons.hide()
	FadeContainer.modulate = deselected_color
	if !exhausted:
		rect_position = default_position
	else:
		rect_position = exhausted_position

func select(category_idx):
	AllyPortrait.select()
	CombatIcons.show(category_idx)
	FadeContainer.modulate = selected_color
	rect_position = selected_position
	return category_idx

func select_category(selected_category_idx, direction):
	return CombatIcons.select_next_category(selected_category_idx, direction)

func select_status_category():
	return CombatIcons.select(4)

func select_no_category():
	CombatIcons.select_no_category()

func open_category_submenu(category_idx):
	for icon in category_zoom_icons:
		icon.visible = false
	last_category_idx = category_idx
	category_zoom_icons[category_idx].visible = true
	CombatIcons.hide()
	Submenu.setup(data, data.get_moves(move_lists[category_idx]))
	Submenu.show()
	QuestMgr.skill_menu_open = move_lists[category_idx]

func on_targeting_started(move_data):
	CurrentMoveLabel.visible = true
	CurrentMoveLabel.text = move_data.label

func on_targeting_cancelled():
	CurrentMoveLabel.visible = false

func on_targeting_completed():
	CurrentMoveLabel.visible = false
	for icon in category_zoom_icons:
		icon.visible = false
	exhausted = true
	rect_position = exhausted_position
	modulate = exhausted_color
	AllyPortrait.deselect()

func _on_Submenu_cancel_submenu():
	CombatIcons.show(last_category_idx)
	category_zoom_icons[last_category_idx].visible = false
	EventBus.emit_signal("cancel_submenu")
	QuestMgr.skill_menu_open = null

func _on_Submenu_select_submenu_item(submenu, move_data):
	EventBus.emit_signal("select_submenu_item", submenu, move_data)


func _on_CombatScreen_start_player_turn(combat_data):
	exhausted = false
	var remaining_shields = []
	for shield in data.shields:
		if !shield.get("shield_destroyed", false):
			remaining_shields.append(shield)
	data.shields = remaining_shields


func _on_CombatScreen_start_enemy_turn(combat_data):
	CombatIcons.hide()
	rect_position = default_position
	modulate = Color.white

func _on_enemy_move_complete(combat_data):
	DamageIndicator.apply_damage(data)

func _on_CombatScreen_player_turn_complete(combat_data):
	AllyPortrait.deselect()


func _on_Ally_cancel_submenu():
	pass # Replace with function body.


func _on_BulletStrikeArea_body_entered(bullet):
	#data.take_damage(bullet.get_damage())
	CombatMgr.emit_signal("attack_bullet_strike", self)
	bullet.ally_strike(data)
	DamageIndicator.take_damage(bullet.get_damage())

func add_positive_effect_bubble(effect_bubble):
	effect_bubble.bubble_setup("apply_positive_ally_effects", Vector2(-180, POSITIVE_BUBBLE_HEIGHT-20), Vector2(180, POSITIVE_BUBBLE_HEIGHT+20))
	#CombatMgr.emit_signal("add_ally_effect_bubble", effect_bubble)
	find_node("EffectBubbles").add_child(effect_bubble)

func _on_damage_all_allies(damage):
	DamageIndicator.take_damage(damage)
	yield(get_tree().create_timer(0.5), "timeout")
	DamageIndicator.apply_damage(data)
	yield(get_tree().create_timer(0.5), "timeout")
	EventBus.emit_signal("check_explore_gameover")

func ally_sp_lost(amt):
	var floater = preload("res://combat/DamageFloater.tscn").instance()
	floater.set_damage(amt, GameData.get_sp_damage_label(amt))
	add_child(floater)
	floater.rect_global_position = SpDamageOrigin.global_position
