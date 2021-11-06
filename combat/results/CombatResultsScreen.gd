extends Node2D

var data = {
	"pollen_water": round(rand_range(0, 9)),
	"pollen_sun": round(rand_range(0, 9)),
	"pollen_soil": round(rand_range(0, 9)),
	"pollen_decay": round(rand_range(0, 1)),
	"damage_done": round(rand_range(1, 9999)),
	"damage_received": round(rand_range(1, 9999)),
	"blocks_made": round(rand_range(1, 9999)),
	"blocks_missed": round(rand_range(1, 9999)),
	"rewards": []
}

func _ready():
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
	trigger_damage_counter(delay)
	delay += 0.25
	trigger_gleam(delay, find_node("BlockGleam"))
	delay += 0.25
	if data.get("rewards", []).size() <= 0:
		hide_rewards(delay)
	else:
		trigger_gleam(delay, find_node("RewardGleam"))
	delay += 0.25
	reveal_rank(delay)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	$AnimationPlayer.play("rank_gleam")

func reveal_rank(delay):
	$Tween.interpolate_method(self, "reveal_rank_amt", 1.0, 0.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)
	
func hide_rewards(delay):
	$Tween.interpolate_method(self, "hide_rewards_amt", 0.0, 1.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)

func reveal_rank_amt(val):
	$RankResults/S.material.set_shader_param("manual_progress", val)	

func hide_rewards_amt(val):
	$StatsRows/Reward.material.set_shader_param("manual_progress", val)	

func trigger_damage_counter(delay):
	pass

func trigger_gleam(delay, gleam_node):
	$Tween.interpolate_property(gleam_node, "position:x", gleam_node.position.x, gleam_node.position.x + 1250, 0.95, Tween.TRANS_CUBIC, Tween.EASE_IN, delay)

func trigger_counter(delay, label_node, value):
	$Tween.interpolate_property(label_node, "number", 0, value, 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT, delay)

func _on_AnimationPlayer_animation_finished(anim_name):
	find_node("AnimationPlayer").play("rank_gleam")
