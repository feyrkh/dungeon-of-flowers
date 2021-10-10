extends Area

var placement_good = false
onready var delay = (hash(name) % 5000)/5000.0 + 1.0

func _ready():
	connect("area_entered", self, "_on_PlacementChecker_area_entered")

func _process(_delta):
	delay -= _delta
	if delay > 0:
		return
	if placement_good:
		call_deferred("queue_free")
	else:
		get_parent().call_deferred("queue_free")
		#print(get_parent().name, " was placed in a bad spot: ", round(self.global_transform.origin.x/3), ", ", round(self.global_transform.origin.z/3))

func _on_PlacementChecker_area_entered(area):
	placement_good = area.has_method("is_valid_prop_area") and area.is_valid_prop_area()
