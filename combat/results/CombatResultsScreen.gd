extends Node2D

var data
var closing = false

func _ready():
	if data == null:
		randomize()
		data = {
			"pollen_water": round(rand_range(0, 9)),
			"pollen_sun": round(rand_range(0, 9)),
			"pollen_soil": round(rand_range(0, 9)),
			"pollen_decay": round(rand_range(0, 1)),
			"damage_given": round(rand_range(1, 9999)),
			"damage_taken": round(rand_range(1, 9999)),
			"blocks_made": round(rand_range(1, 9999)),
			"blocks_missed": round(rand_range(1, 9999)),
			"rewards": {"apple": round(rand_range(0, 2))}
		}
	$Background.playing = true
	for child in $StatsRows.get_children():
		if child is AnimatedSprite:
			child.playing = true
	var delay = 0.25
	trigger_gleam(delay, find_node("PollenGleam"))
	delay += 0.25
	trigger_counter(delay+0.4, find_node("SoilLabel"), data.get("pollen_soil", 0))
	trigger_counter(delay+0.55, find_node("SunLabel"), data.get("pollen_sun", 0))
	trigger_counter(delay+0.7, find_node("WaterLabel"), data.get("pollen_water", 0))
	trigger_counter(delay+0.85, find_node("DecayLabel"), data.get("pollen_decay", 0))

	trigger_gleam(delay, find_node("DamageGleam"))
	trigger_counter(delay+0.7, find_node("DamageGivenLabel"), data.get("damage_given", 0))
	trigger_counter(delay+0.7, find_node("DamageTakenLabel"), data.get("damage_taken", 0))
	trigger_damage_bar(delay+0.7)
	delay += 0.25
	trigger_gleam(delay, find_node("BlockGleam"))
	var block_pct = 50
	var damage_pct
	if data.get("damage_given", 0) == 0 and data.get("damage_taken", 0) == 0:
		damage_pct = 0.5
	else:
		damage_pct = data.get("damage_given", 0) / float(data.get("damage_given", 0) + data.get("damage_taken", 0))
	if data.get("blocks_made",0) != 0 or data.get("blocks_missed",0) != 0:
		block_pct = int(float(data.get("blocks_made",0))/(data.get("blocks_made",0)+data.get("blocks_missed",0))*100)
	var badge_scene = set_badge_texture(block_pct, damage_pct*100)

	trigger_counter(delay+0.7, find_node("BlockPercentLabel"), block_pct)
	trigger_block_bar(delay+0.7)
	delay += 0.25
	var rewards = data.get("rewards", {})
	for reward in rewards.keys():
		if !rewards[reward]:
			rewards.erase(reward)
	if data.get("rewards", {}).size() <= 0:
		hide_rewards(delay)
	else:
		trigger_gleam(delay, find_node("RewardGleam"))
		populate_rewards(delay+0.55)
	delay += 0.25
	reveal_rank(delay)
	$Tween.start()
	set_process(false)
	yield($Tween, "tween_all_completed")
	set_process(true)
	$AnimationPlayer.play("rank_gleam")

func set_badge_texture(block_pct, damage_pct):
	var badge = 0
	var badges = ["D", "D", "C", "C", "B", "B", "A", "A", "S"]
	if block_pct < 25:
		badge += 0
	elif block_pct < 45:
		badge += 1
	elif block_pct < 70:
		badge += 2
	elif block_pct < 90:
		badge += 3
	else:
		badge += 4
	if damage_pct < 30:
		badge += 0
	elif damage_pct < 45:
		badge += 1
	elif damage_pct < 75:
		badge += 2
	elif damage_pct <= 90:
		badge += 3
	else:
		badge += 4
	badge = clamp(badge, 0, badges.size())
	badge = badges[badge]
	$RankResults/S.texture = load("res://art_exports/ui_battle_results/ui_results_RANK_"+badge+".png")

func _process(delta):
	if closing:
		return
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
		closing = true
		$RankResults/Gleam.visible = false
		CombatMgr.close_results(self)

func populate_rewards(delay):
	var x_ofs = 0
	var y_ofs = 0
	var max_y_on_row = 0
	var rewards = data.get("rewards", {})
	for reward in rewards.keys():
		EventBus.emit_signal("acquire_item", reward, rewards[reward])
		var tex = load("res://img/item/"+reward+".png")
		if (!tex):
			continue
		var sprite = Sprite.new()
		$ItemSpawn.add_child(sprite)
		sprite.light_mask = $ItemSpawn.light_mask
		sprite.texture = tex
		sprite.centered = false
		sprite.position = Vector2(x_ofs, y_ofs)
		if sprite.position.x + sprite.texture.get_width() > 1750:
			sprite.position.x = 0
			y_ofs += max_y_on_row
			max_y_on_row = 0
			sprite.position.y = y_ofs
		x_ofs += sprite.texture.get_width() * 1.1
		var label = preload("res://art_exports/ui_common/BattleFontLabel.tscn").instance()
		label.light_mask = $ItemSpawn.light_mask
		label.prefix = "x"
		label.position = Vector2(sprite.texture.get_width()/2, sprite.texture.get_height() + 22)
		label.text = str(rewards[reward])
		sprite.add_child(label)
		if sprite.texture.get_height() > max_y_on_row:
			max_y_on_row = sprite.texture.get_height()
		#sprite.set_material($RankResults/S.get_material().duplicate(true))
		#sprite.get_material().set_shader_param("manual_progress", 1.0)
		label.visible = false
		sprite.visible = false
		$Tween.interpolate_property(sprite, "position:y", sprite.position.y + 30, sprite.position.y - 30, 0.15, Tween.TRANS_LINEAR, Tween.EASE_OUT, delay)
		$Tween.interpolate_property(sprite, "position:y", sprite.position.y - 30, sprite.position.y, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN, delay + 0.15)
		Util.delay_call(delay, self, "reveal_item", [sprite, label])
		delay += 0.15

func reveal_item(sprite, label):
	sprite.visible = true
	Util.delay_call(0.5, self, "reveal_item_label", [label])

func reveal_item_label(label):
	label.visible = true

func reveal_rank(delay):
	$Tween.interpolate_method(self, "reveal_rank_amt", 1.0, 0.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)

func hide_rewards(delay):
	$Tween.interpolate_method(self, "hide_rewards_amt", 0.0, 1.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)

func reveal_rank_amt(val):
	$RankResults/S.material.set_shader_param("manual_progress", val)

func hide_rewards_amt(val):
	$StatsRows/Reward.material.set_shader_param("manual_progress", val)

func trigger_gleam(delay, gleam_node):
	gleam_node.visible = true
	$Tween.interpolate_property(gleam_node, "position:x", gleam_node.position.x, gleam_node.position.x + 1250, 0.95, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)

func trigger_counter(delay, label_node, value):
	$Tween.interpolate_property(label_node, "number", 0, value, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT, delay)

func trigger_damage_bar(delay):
	var bar = find_node("DamageBar")
	$Tween.interpolate_property(bar, "left_val", 0, data.get("damage_given", 0), 1, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT, delay)
	$Tween.interpolate_property(bar, "right_val", 0, data.get("damage_taken", 0), 0.8, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT, delay)

func trigger_block_bar(delay):
	var bar = find_node("BlockBar")
	$Tween.interpolate_property(bar, "left_val", 0, data.get("blocks_made", 0), 1, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT, delay)
	$Tween.interpolate_property(bar, "right_val", 0, data.get("blocks_missed", 0), 0.8, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT, delay)

func _on_AnimationPlayer_animation_finished(anim_name):
	find_node("AnimationPlayer").play("rank_gleam")
