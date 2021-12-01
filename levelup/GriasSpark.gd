extends Node2D

const ROTATE_SPEED_PER_ENERGY = 30
const BASE_MOVE_SPEED = 64

onready var Core = find_node("Core")
onready var Spark1 = find_node("Spark1")
onready var Spark2 = find_node("Spark2")
onready var Spark3 = find_node("Spark3")
onready var Spark4 = find_node("Spark4")

export(float) var energy = 1.0
var speed = 1.0

func _ready():
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

func generate_spark_movement(spark, start, finish, offset):
	$Tween.interpolate_property(spark, "position", start, finish, 1, 0, 2, offset)
	$Tween.interpolate_property(spark, "scale", Vector2(0.2, 0.2), Vector2.ONE, 0.5, 0, 2, offset)
	$Tween.interpolate_property(spark, "scale", Vector2.ONE, Vector2(0.2, 0.2), 0.5, 0, 2, 0.5+offset)
	$Tween.interpolate_property(spark, "scale", Vector2(0.2, 0.2), Vector2.ZERO, 0.05, 0, 2, 1.0+offset)
	#$Tween.interpolate_property(spark, "scale", Vector2.ZERO, Vector2(0.3, 0.3), 0.05, 0, 2, 1.95+offset)

func _process(delta):
	rotation_degrees += ROTATE_SPEED_PER_ENERGY * energy * delta
