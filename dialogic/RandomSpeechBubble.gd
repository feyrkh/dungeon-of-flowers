extends MarginContainer

var texture_size:Vector2
var texture_rect:Vector2
var valid_range:Vector2

func _ready():
	texture_size = $TextureOverlay.texture.get_size()
	texture_rect = $TextureOverlay.region_rect.size
	valid_range = texture_size - texture_rect
	
func move_paper():
	$TextureOverlay.region_rect.position.x = int(rand_range(0, valid_range.x))
	$TextureOverlay.region_rect.position.y = int(rand_range(0, valid_range.y))
	$TextureOverlay.flip_h = randf() >= 0.5;
	$TextureOverlay.flip_v = randf() >= 0.5;

func _on_Timer_timeout():
	move_paper()
