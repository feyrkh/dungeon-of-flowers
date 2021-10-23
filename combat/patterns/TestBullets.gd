tool
extends Node2D

export(bool) var save_pattern = false setget _on_SaveButton_pressed
export(int) var multiplier = 1
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var bullets_per_enemy = $BulletPattern.num_bullets
var multiplier_increase = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$BulletPattern.global_target_point = $AllyPortraits/Ally2.rect_global_position + Vector2(50, 0)
	$BulletPattern.target_width = 400
	$Label.text = "Enemies: 1\nBullets: %d" % bullets_per_enemy
	update_bullet_count()
	$BulletPattern._ready()
	$BulletPattern.start_attack()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_BulletPattern_attack_complete():
	yield(get_tree().create_timer(3), "timeout")
	multiplier = multiplier + multiplier_increase
	update_bullet_count()
	for child in $BulletPattern.get_children():
		child.queue_free()
	$BulletPattern._ready()
	$BulletPattern.start_attack()

func update_bullet_count():
	$BulletPattern.num_bullets = bullets_per_enemy * multiplier
	$Label.text = "Enemies: %d\nBullets: %d" % [multiplier, $BulletPattern.num_bullets]

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


func _on_IncreaseEnemies_toggled(button_pressed):
	if button_pressed:
		multiplier_increase = 1
	else:
		multiplier_increase = 0
