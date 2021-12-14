extends Node2D

const ROTATE_SPEED_PER_ENERGY = 30
const BASE_MOVE_SPEED = 64
const ENERGY_PER_TILE = 0.25

onready var Core = find_node("Core")
onready var Spark1 = find_node("Spark1")
onready var Spark2 = find_node("Spark2")
onready var Spark3 = find_node("Spark3")
onready var Spark4 = find_node("Spark4")

export(float) var energy = 0.5
var speed = 1.0
var direction:Vector2 = Vector2.ZERO
var map_position:Vector2 = Vector2.ZERO
var tilemap_mgr:TilemapMgr
var fog_clear_color:Color = Color.black
var element

func _ready():
	rotation_degrees = randi()%360
	Spark1.visible = energy >= 1
	Spark2.visible = energy >= 2
	Spark3.visible = energy >= 3
	Spark4.visible = energy >= 4
	generate_spark_movement(Spark1, Vector2(-35, 0), Vector2(35, 0), 0)
	generate_spark_movement(Spark2, Vector2(0, -35), Vector2(0, 35), 0.25)
	generate_spark_movement(Spark3, Vector2(-25, 25), Vector2(25, -25), 0.5)
	generate_spark_movement(Spark4, Vector2(25, 25), Vector2(-25, -25), 0.75)
	$Tween.repeat = true
	$Tween.start()
	scale = Vector2.ZERO
	var tween = Util.one_shot_tween(self)
	tween.interpolate_property(self, "scale", Vector2.ZERO, Vector2.ONE, 0.5)
	tween.start()

func setup(core_node:GriasCore):
	self.direction = core_node.get_next_direction()
	self.map_position = core_node.map_position
	self.tilemap_mgr = core_node.tilemap_mgr
	self.position = self.map_position * 64 + Vector2(32, 32)
	$Core.texture = C.element_image(core_node.element)
	fog_clear_color = C.element_color(core_node.element)
	element = core_node.element
	begin_move(map_position, map_position + direction)

func begin_move(start, end):
	var tween = Util.one_shot_tween(self)
	var move_time = 64.0/BASE_MOVE_SPEED/speed
	tween.interpolate_property(self, "position", position, position + direction * BASE_MOVE_SPEED * speed, move_time)
	tween.interpolate_callback(self, move_time, "finish_move", end)
	tween.start()

func finish_move(end_position):
	map_position = end_position
	match tilemap_mgr.get_tile_name("fog", end_position.x, end_position.y):
		"chaos1": hit_chaos(end_position, -0.1, 0.5)
		"chaos2": hit_chaos(end_position, 1, 0.6)
		"chaos3": hit_chaos(end_position, 2, 0.7)
		"chaos4": hit_chaos(end_position, 3, 0.8)
	#energy -= ENERGY_PER_TILE
	Spark1.visible = energy >= 1
	Spark2.visible = energy >= 2
	Spark3.visible = energy >= 3
	Spark4.visible = energy >= 4
	var component = tilemap_mgr.get_tile_scene("component", end_position)
	if component and component.has_method("spark_arrived"):
		component.spark_arrived(self, end_position)
	if energy <= 0:
		queue_free()
	begin_move(map_position, map_position+direction)

func hit_chaos(pos, min_energy, fog_color):
	if energy >= min_energy:
		EventBus.emit_signal("grias_levelup_clear_fog", pos, fog_clear_color)
	else:
		EventBus.emit_signal("grias_levelup_fail_clear_fog", pos, fog_clear_color)
		energy -= 1000

func generate_spark_movement(spark, start, finish, offset):
	$Tween.interpolate_property(spark, "position", start, finish, 1, 0, 2, offset)
	$Tween.interpolate_property(spark, "scale", Vector2(0.2, 0.2), Vector2.ONE, 0.5, 0, 2, offset)
	$Tween.interpolate_property(spark, "scale", Vector2.ONE, Vector2(0.2, 0.2), 0.5, 0, 2, 0.5+offset)
	$Tween.interpolate_property(spark, "scale", Vector2(0.2, 0.2), Vector2.ZERO, 0.05, 0, 2, 1.0+offset)
	#$Tween.interpolate_property(spark, "scale", Vector2.ZERO, Vector2(0.3, 0.3), 0.05, 0, 2, 1.95+offset)

func _process(delta):
	rotation_degrees += ROTATE_SPEED_PER_ENERGY * energy * delta
	energy -= delta * ENERGY_PER_TILE
	if energy < 0.5:
		modulate.a = energy*2

func add_meridian_energy(efficiency):
	energy += ENERGY_PER_TILE * efficiency

func redirect(new_dir):
	if new_dir == null:
		return
	direction = new_dir
