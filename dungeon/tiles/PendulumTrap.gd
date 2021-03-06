extends DungeonEntity

export(bool) var firing = true
export(float) var damage = 3
export(float) var seconds_per_rotation = 5
export(Curve) var rotation_curve:Curve
export(float) var rotation_percent = 0
var pause_percent = 0.2

onready var Rotating = find_node("Rotating")

func post_config(map_config):
	transform.origin.y = transform.origin.y + 3
	var new_rotation = rotation_curve.interpolate(rotation_percent)
	Rotating.rotation_degrees.z = new_rotation
	#Rotating.transform.basis = Rotating.transform.basis.rotated(Vector3.BACK, deg2rad(new_rotation))

func pre_save_game():
	update_config({"firing":firing, "rotation_percent":rotation_percent})

func post_load_game():
	pass

func _on_Area_area_entered(area):
	if area.owner.has_method("trap_hit"):
		area.owner.trap_hit(self, null)

func _process(delta):
	if CombatMgr.is_in_combat or !firing:
		return
	rotation_percent += delta/seconds_per_rotation
	if rotation_percent > 1 + pause_percent:
		rotation_percent = fmod(rotation_percent, 1+pause_percent)
	var next_rotation = rotation_curve.interpolate(rotation_percent) * 1.01
	#Rotating.transform.basis = Rotating.transform.basis.rotated(Vector3.BACK, deg2rad(new_rotation))
	Rotating.rotation_degrees.z = next_rotation
