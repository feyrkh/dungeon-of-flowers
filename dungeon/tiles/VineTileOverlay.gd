extends DungeonEntity

const ADJACENT_VINE_DELAY = 1
var destroying = false
var counter = 0

func _ready():
	set_process(false)

func on_map_place(_dungeon, layer_name:String, cell:Vector2):
	.on_map_place(_dungeon, layer_name, cell)
	var adjacent_vines = count_adjacent_vines()
	if adjacent_vines < 2:
		destroy_vines()

func _process(delta):
	if !destroying:
		return
	counter -= delta
	if counter <= 0:
		finish_destroying_vines()

func destroy_vines(delay=0):
	if destroying:
		return
	destroying = true
	set_process(true)

func finish_destroying_vines():
	set_process(false)
	print("Destroying vines at ", map_position)
	var tween = Util.one_shot_tween(self)
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var adjacent_vine = dungeon.get_tile_scene(map_layer, map_position + dir)
		if adjacent_vine and adjacent_vine.has_method("destroy_vines"):
			tween.interpolate_callback(adjacent_vine, ADJACENT_VINE_DELAY, "destroy_vines", ADJACENT_VINE_DELAY)
	$Particles.emitting = true
	tween.interpolate_property($Sprite3D, "modulate", Color.white, Color.transparent, ADJACENT_VINE_DELAY)
	tween.start()
	print("vines destroyed at ", map_position, " yielding until tween finished")
	yield(get_tree().create_timer(ADJACENT_VINE_DELAY*1.5), "timeout")
	print("vines destroyed at ", map_position, " clearing tile")
	change_tile(-1)
	print("vines destroyed at ", map_position, " freeing myself")
	queue_free()

func count_adjacent_vines():
	var adjacent_vines = 0
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var adjacent_vine = dungeon.get_tile_name("floor_overlay", (map_position + dir).x, (map_position + dir).y)
		if adjacent_vine == "~vines":
			adjacent_vines += 1
		var adjacent_flower = dungeon.get_tile_name("fixtures", (map_position + dir).x, (map_position + dir).y)
		if adjacent_flower == '~flower' or adjacent_flower == '~pollen_spawn':
			adjacent_vines += 1
	var adjacent_flower = dungeon.get_tile_name("fixtures", map_position.x, map_position.y)
	if adjacent_flower == '~flower' or adjacent_flower == '~pollen_spawn':
		adjacent_vines += 1
	return adjacent_vines
