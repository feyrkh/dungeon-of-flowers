extends Node2D


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
	$BulletPattern._ready()
