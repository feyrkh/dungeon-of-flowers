extends Sprite3D

const motions = [
	{"time":1, "start":Vector3(-3, 0, 0), "end":Vector3(3, 0, 0)},
	{"time":6, "start":Vector3(-3, 0, 0), "end":Vector3(3, 0, 0)},
	{"time":6, "start":Vector3(-1.5, 0, -3), "end":Vector3(1.5, 0, 3)},
	{"time":6, "start":Vector3(1.5, 0, -3), "end":Vector3(-1.5, 0, 3)},
	{"time":6, "start":Vector3(0, 0, 3), "end":Vector3(0, 0, -6)},
]
const OPACITY_VISIBLE = 0.5

export(Array, Texture) var shapes = []

var show_shadows = false
var target_opacity = 0
onready var default_origin = self.transform.origin

func _ready():
	if shapes.size() == 0:
		return
	$Timer.connect("timeout", self, "start_movement")
	EventBus.connect("new_player_location", self, "update_opacity")
	#modulate.a = 0
	$Tween.connect("tween_all_completed", self, "finish_motion")

func finish_motion():
	modulate.a = 0
	target_opacity = 0

func update_opacity(x, y, rot):
	show_shadows = GameData.dungeon.get_pollen_level(Vector2(x,y)) > 2
	if !show_shadows and $Tween.is_active():
		$Tween.remove_all()
		$Tween.interpolate_property(self, "modulate:a", modulate.a, 0, 0.25)
		$Tween.start()

func start_movement():
	if !show_shadows or $Tween.is_active():
		return
	texture = shapes[randi()%shapes.size()]
	flip_h = randf() > 0.5
	$Tween.remove_all()
	var motion = motions[randi()%motions.size()]
	var start = motion["start"]
	var end = motion["end"]
	if randf() < 0.5:
		var tmp = start
		start = end
		end = tmp
	$Tween.interpolate_property(self, "transform:origin", default_origin + start, default_origin + end, motion["time"])
	$Tween.interpolate_property(self, "modulate:a", 0, OPACITY_VISIBLE, motion["time"]/4.0)
	$Tween.interpolate_property(self, "modulate:a", OPACITY_VISIBLE, 0, motion["time"]/4.0, 0, 2, motion["time"]/4.0*3)
	$Tween.start()
