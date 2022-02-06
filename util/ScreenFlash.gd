extends ColorRect

onready var tween = $Tween

func flash(t:float, c:Color):
	tween.interpolate_property(self, "color", Color.transparent, c, t/2.0)
	tween.interpolate_property(self, "color", c, Color.transparent, t/2.0, t/2.0)
	tween.start()
	tween.connect("tween_all_completed", self, "queue_free")
