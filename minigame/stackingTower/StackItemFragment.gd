extends Node2D

const ROTATE_SPEED = 30
const SIDE_SPEED = 60
const DOWN_ACCEL = 60
const ALPHA_DRAIN_SEC = 3

var move_dir
var down_speed = 0


func left_fragment(overhang):
	move_dir = -1
	$Img.region_enabled = true
	$Img.region_rect = Rect2(0, 0, overhang, $Img.texture.get_size().y)

func right_fragment(overhang):
	move_dir = 1
	$Img.region_enabled = true
	$Img.region_rect = Rect2($Img.texture.get_size().x - overhang, 0, overhang, $Img.texture.get_size().y)
	print("region_rect: ", $Img.region_rect)
	print("size: ", $Img.texture.get_size())
	$Img.position.x += $Img.texture.get_size().x - overhang

func _physics_process(delta):
	rotation_degrees += delta * ROTATE_SPEED * move_dir
	position.x += delta * SIDE_SPEED * move_dir
	down_speed += delta * DOWN_ACCEL
	position.y += delta * down_speed
	modulate.a = max(0, modulate.a - delta/ALPHA_DRAIN_SEC)
	if modulate.a <= 0:
		queue_free()

