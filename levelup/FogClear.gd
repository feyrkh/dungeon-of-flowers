extends Node2D

func fade(fade_color:Color):
	var fade_time = 3
	var tween = Util.one_shot_tween(self)
	tween.interpolate_property($FogTile, "modulate", fade_color, Color.transparent, fade_time)
	tween.interpolate_property($Swirl, "modulate", fade_color, Color.transparent, fade_time)
	tween.interpolate_property($Swirl, "scale", Vector2.ONE, Vector2.ZERO, fade_time)
	tween.interpolate_property($Swirl, "rotation_degrees", 0, 360*9, fade_time, Tween.TRANS_EXPO, Tween.EASE_IN)
	tween.interpolate_callback(self, fade_time, "queue_free")
	tween.start()

func fail(fade_color:Color):
	var fade_time = 1
	var tween = Util.one_shot_tween(self)
	$FogTile.queue_free()
	tween.interpolate_property($Swirl, "modulate", fade_color, Color.transparent, fade_time)
	tween.interpolate_property($Swirl, "scale", Vector2(0.5, 0.5), Vector2.ZERO, fade_time)
	tween.interpolate_property($Swirl, "rotation_degrees", 0, 360*9, fade_time, Tween.TRANS_EXPO, Tween.EASE_IN)
	tween.interpolate_callback(self, fade_time, "queue_free")
	tween.start()
