extends MapEntity

const DIRS = {
	Vector2.UP: C.FACING_DOWN,
	Vector2.DOWN: C.FACING_UP,
	Vector2.LEFT: C.FACING_RIGHT,
	Vector2.RIGHT: C.FACING_LEFT,
}

var efficiency = 0.5
var facing = C.FACING_UP setget set_facing
var _focus_power_cache = null

func grias_pre_save_levelup():
	var save_data = {
		"efficiency": efficiency,
		"facing": facing,
	}
	update_config(save_data)
	
func on_map_place(_tilemap_mgr, layer_name:String, cell:Vector2):
	.on_map_place(_tilemap_mgr, layer_name, cell)
	position = position + Vector2(32, 32)
	EventBus.emit_signal("grias_reset_focus_power_cache")
	render_component()

func set_initial_rotation(dir:Vector2, initial_facing:float):
	var possible_focuser = tilemap_mgr.get_tile_scene("component", map_position + dir)
	if possible_focuser and possible_focuser.has_method("get_focus_power"):
		facing = initial_facing

func set_rotation_on_build():
	set_initial_rotation(Vector2.LEFT, C.FACING_LEFT)
	set_initial_rotation(Vector2.DOWN, C.FACING_DOWN)
	set_initial_rotation(Vector2.RIGHT, C.FACING_RIGHT)
	set_initial_rotation(Vector2.UP, C.FACING_UP)

func get_component_label():
	return "Focus (+"+str(round(get_focus_power()*100))+"%)"

func get_description():
	return "A support node which can boost the energy capacity of a nearby powered nexus. Multiple focusing nodes may be chained together, with diminishing returns."

func get_component_menu_items():
	EventBus.emit_signal("grias_component_description", get_description())
	# TODO: delete
	return []

func get_focus_power():
	if _focus_power_cache == null:
		calculate_focus_power()
	return _focus_power_cache

func reset_focus_power_cache():
	_focus_power_cache = null

func calculate_focus_power():
	_focus_power_cache = efficiency
	for dir in DIRS:
		var possible_focuser = tilemap_mgr.get_tile_scene("component", map_position + dir)
		if possible_focuser and possible_focuser.has_method("get_focus_power") and possible_focuser.get("facing") != null:
			var opposite_dir = DIRS[dir]
			if possible_focuser.facing != opposite_dir:
				continue # not facing me so I don't get any focus benefit
			_focus_power_cache += possible_focuser.get_focus_power() * efficiency

func set_facing(val):
	facing = val
	reset_focus_power_cache()

func _ready() -> void:
	EventBus.connect("grias_pre_save_levelup", self, "grias_pre_save_levelup")
	EventBus.connect("grias_reset_focus_power_cache", self, "reset_focus_power_cache")
	set_facing(facing)
	render_component()

func render_component():
	rotation_degrees = facing

func spark_arrived(spark, tile_coords):
	spark.queue_free()
	EventBus.emit_signal("grias_levelup_fail_clear_fog", map_position, Color.black)

func can_cursor_rotate():
	return true

func cursor_rotate(direction):
	set_facing(posmod(round(facing + 90*direction), 360))
	render_component()
	EventBus.emit_signal("grias_reset_focus_power_cache")
