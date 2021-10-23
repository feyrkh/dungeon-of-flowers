tool
extends Node2D

export(bool) var save_pattern = false setget _on_SaveButton_pressed
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$BulletPattern.global_target_point = $AllyCombatDisplay.rect_global_position + Vector2(50, 0)
	$BulletPattern.target_width = 400


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_BulletPattern_attack_complete():
	yield(get_tree().create_timer(3), "timeout")
	
	for child in $BulletPattern.get_children():
		child.queue_free()
	$BulletPattern._ready()


func _on_SaveButton_pressed(val):
	var scene = preload("res://combat/patterns/BulletPattern.tscn").instance()
	scene.num_bullets = $BulletPattern.num_bullets
	scene.attack_time = $BulletPattern.attack_time
	scene.min_speed = $BulletPattern.min_speed
	scene.max_speed = $BulletPattern.max_speed
	scene.bullet_timing = $BulletPattern.bullet_timing.duplicate()
	scene.bullet_target = $BulletPattern.bullet_target.duplicate()
	scene.bullet_speed = $BulletPattern.bullet_speed.duplicate()
	scene.bullet_origin_scene = $BulletPattern.bullet_origin_scene
	scene.bullet_scene = $BulletPattern.bullet_scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)
	ResourceSaver.save("res://combat/patterns/_NEW_BULLET_PATTERN.tscn", packed_scene)
