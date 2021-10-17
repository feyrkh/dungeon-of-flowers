tool
extends MarginContainer

const SHADER_DURATION = 0.25

signal dialog_box_destroyed()

var texture_size:Vector2
var texture_rect:Vector2
var valid_range:Vector2
export(bool) var allow_flip_h = true
export(bool) var allow_flip_v = true
var fade_in_progress = 0.0

func _ready():
	texture_size = $ViewportContainer/Viewport/Container/TextureOverlay.texture.get_size()
	texture_rect = $ViewportContainer/Viewport/Container/TextureOverlay.region_rect.size
	valid_range = texture_size - texture_rect
	$ViewportContainer/Viewport/Container/ui_speechbubble.material.set_shader_param("progress", 0.0)
	load_dialog_box()

func _process(delta):
	fade_in_progress += delta/SHADER_DURATION
	$ViewportContainer/Viewport/Container/ui_speechbubble.material.set_shader_param("progress", fade_in_progress)
	if fade_in_progress > 1.0:
		set_process(false)

func load_dialog_box():
	$ViewportContainer/Viewport/Container/ui_speechbubble.set_material($ViewportContainer/Viewport/Container/ui_speechbubble.get_material().duplicate(true))
	$ViewportContainer/Viewport/Container/ui_speechbubble.material.set_shader_param("duration", SHADER_DURATION)
	set_process(true)

func move_paper():
	$ViewportContainer/Viewport/Container/TextureOverlay.region_rect.position.x = int(rand_range(0, valid_range.x))
	$ViewportContainer/Viewport/Container/TextureOverlay.region_rect.position.y = int(rand_range(0, valid_range.y))
	if allow_flip_h: $ViewportContainer/Viewport/Container/TextureOverlay.flip_h = randf() >= 0.5;
	if allow_flip_v: $ViewportContainer/Viewport/Container/TextureOverlay.flip_v = randf() >= 0.5;

func _on_Timer_timeout():
	move_paper()

func set_background_flip(flip):
	if flip:
		$ViewportContainer/Viewport/Container/ui_speechbubble.flip_h = true
		$ViewportContainer/Viewport/Container/Light2D.scale.x = -1
	else:
		$ViewportContainer/Viewport/Container/ui_speechbubble.flip_h = false
		$ViewportContainer/Viewport/Container/Light2D.scale.x = 1
