extends Node2D

signal stack_collide(dropped_item, stack_item)
signal dangerzone_collide(dropped_item)

const STACK_ITEM_FRAGMENT = preload("res://minigame/stackingTower/StackItemFragment.tscn")

var collide_type = "stackitem"
var allow_collide = true

func _ready():
	$Area2D/CollisionShape2D.shape = $Area2D/CollisionShape2D.shape.duplicate()
	pass

func _on_Area2D_area_entered(area):
	if !allow_collide: 
		return
	allow_collide = false
	$Area2D.collision_mask = 0
	if area.get_parent().collide_type == "stackitem":
		emit_signal("stack_collide", self, area)
	elif area.get_parent().collide_type == "dangerzone":
		emit_signal("dangerzone_collide", self)

func land_on_stack(top_left:Vector2, top_right:Vector2):
	print("----")
	print("tl: ", top_left, " tr: ", top_right)
	global_position.y = top_left.y - $ColorRect.get_global_rect().size.y * scale.y
	var left_overhang = top_left.x - global_position.x
	var right_overhang = ($ColorRect.rect_global_position.x + $ColorRect.rect_size.x * scale.x) - top_right.x
	print("RGP.x: ", $ColorRect.rect_global_position.x, "; RS: ", $ColorRect.rect_size.x * scale.x, "; TR: ", top_right.x, "; ROH: ", right_overhang)
	if left_overhang > 0:
		$ColorRect.rect_size.x = $ColorRect.rect_size.x - left_overhang/scale.x
		$ColorRect.rect_position.x = $ColorRect.rect_position.x + left_overhang/scale.x
		print("Before: l-oh: ", left_overhang, " extents.x: ", $Area2D/CollisionShape2D.shape.extents.x, " pos.x: ", $Area2D.position.x)
		var frag = STACK_ITEM_FRAGMENT.instance()
		get_parent().add_child(frag)
		frag.global_position = global_position
		frag.left_fragment(left_overhang)
	if right_overhang > 0:
		print("Before: r-oh: ", right_overhang, " extents.x: ", $Area2D/CollisionShape2D.shape.extents.x, " pos.x: ", $Area2D.position.x)
		$ColorRect.rect_size.x = $ColorRect.rect_size.x - right_overhang/scale.x
		var frag = STACK_ITEM_FRAGMENT.instance()
		get_parent().add_child(frag)
		frag.global_position = global_position
		frag.right_fragment(right_overhang)
	$Area2D/CollisionShape2D.shape.extents.x = ($ColorRect.rect_size.x/2)
	$Area2D.global_position = $ColorRect.rect_global_position + $ColorRect.rect_size*scale.x/2
	print("After: l-oh: ", left_overhang, " extents.x: ", $Area2D/CollisionShape2D.shape.extents.x, " pos.x: ", $Area2D.position.x)
	print("After: r-oh: ", right_overhang, " extents.x: ", $Area2D/CollisionShape2D.shape.extents.x, " pos.x: ", $Area2D.position.x)
	$Img.region_enabled = true
	$Img.region_rect = Rect2($ColorRect.rect_position.x, $ColorRect.rect_position.y, $ColorRect.rect_size.x, $ColorRect.rect_size.y)
	$Img.position.x = $ColorRect.rect_position.x
	
