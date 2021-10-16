tool
extends MarginContainer


var texture_size:Vector2
var texture_rect:Vector2
var valid_range:Vector2
export(bool) var allow_flip_h = true
export(bool) var allow_flip_v = true

func _ready():
	texture_size = $ViewportContainer/Viewport/TextureOverlay.texture.get_size()
	texture_rect = $ViewportContainer/Viewport/TextureOverlay.region_rect.size
	valid_range = texture_size - texture_rect
	
func move_paper():
	$ViewportContainer/Viewport/TextureOverlay.region_rect.position.x = int(rand_range(0, valid_range.x))
	$ViewportContainer/Viewport/TextureOverlay.region_rect.position.y = int(rand_range(0, valid_range.y))
	if allow_flip_h: $ViewportContainer/Viewport/TextureOverlay.flip_h = randf() >= 0.5;
	if allow_flip_v: $ViewportContainer/Viewport/TextureOverlay.flip_v = randf() >= 0.5;

func _on_Timer_timeout():
	move_paper()

func set_background_flip(flip):
	if flip:
		$ViewportContainer/Viewport/ui_speechbubble.flip_h = true
		$ViewportContainer/Viewport/Light2D.scale.x = -1
	else:
		$ViewportContainer/Viewport/ui_speechbubble.flip_h = false
		$ViewportContainer/Viewport/Light2D.scale.x = 1
