extends DungeonTransient

var units_per_second = 9
var damage = 10

func setup(map_config):
	Util.config(self, map_config)

func post_load_game():
	$PerspectiveSprite.refresh_perspective()

func _on_Area_area_entered(area):
	if area.owner.has_method("trap_hit"):
		area.owner.trap_hit(self, transform.basis.z*3)
	queue_free()

func _physics_process(delta):
	transform.origin -= transform.basis.z * delta * units_per_second
