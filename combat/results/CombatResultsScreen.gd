extends Node2D

func _ready():
	$Background.playing = true
	for child in $StatsRows.get_children():
		if child is AnimatedSprite:
			child.playing = true
	find_node("AnimationPlayer").play("rank_gleam")


func _on_AnimationPlayer_animation_finished(anim_name):
	find_node("AnimationPlayer").play("rank_gleam")
