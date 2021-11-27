extends DungeonEntity

export(bool) var firing = true
export(float) var damage = 20
export(float) var seconds_per_rotation = 5
export(Curve) var rotation_curve:Curve
export(float) var rotation_percent = 0
var prev_rotation = 0

onready var Rotating = find_node("Rotating")

func post_config(map_config):
	transform.origin.y = transform.origin.y + 3
	var new_rotation = rotation_curve.interpolate(rotation_percent)
	Rotating.rotation_degrees.z = new_rotation
	#Rotating.transform.basis = Rotating.transform.basis.rotated(Vector3.BACK, deg2rad(new_rotation))

func pre_save_game():
	update_config({"firing":firing, "rotation_percent":rotation_percent, "prev_rotation":prev_rotation})

func post_load_game():
	pass

func _on_Area_area_entered(area):
	if area.owner.has_method("trap_hit"):
		area.owner.trap_hit(self, null)

func _process(delta):
	if CombatMgr.is_in_combat: 
		return
	rotation_percent += delta/seconds_per_rotation
	if rotation_percent > 1:
		rotation_percent -= 1
	var next_rotation = rotation_curve.interpolate(rotation_percent)
	#Rotating.transform.basis = Rotating.transform.basis.rotated(Vector3.BACK, deg2rad(new_rotation))
	Rotating.rotation_degrees.z = next_rotation
