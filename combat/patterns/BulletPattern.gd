extends Node2D

signal attack_complete()

export(int) var num_bullets = 10;
export(float) var attack_time = 10;
export(float) var min_speed = 300;
export(float) var max_speed = 800;
export(Curve) var bullet_timing;
export(Curve) var bullet_target;
export(Curve) var bullet_speed;
export(String) var bullet_origin_scene;
export(String) var bullet_scene = "res://combat/AttackBullet.tscn";

var bullet_origin;
var bullet_prototype:PackedScene;
var bullets = []
var origin_follow:PathFollow2D
var global_target_point:Vector2 # Left edge of the target, set externally by the attacker
var target_width:float = 100    # width of the target, set externally by the attacker

var curve_offset = 0.0 # How far along the various curves we moved - 0..1, where 1 means attack_time seconds have elapsed
var timing_accum_per_bullet # How much weighted timing value we need to accumulate between each bullet. 
							#Calculated by summing the value of every point of the curve at 1% intervals (0.01s * attack_time), then dividing by number of bullets
var timing_accum	# How much weighted time has passed 
var next_bullet_fired_at # The weighted time at which the next bullet will be fired
var origin_curve_center:Vector2

func _ready():
	curve_offset = 0
	bullet_origin = load(bullet_origin_scene).instance()
	add_child(bullet_origin)
	if bullet_origin.get_child_count() > 0:
		bullet_origin = bullet_origin.get_child(0)
	var min_x = 0
	var max_x = 0
	var min_y = 0
	var max_y = 0
	for p in bullet_origin.curve.get_baked_points():
		if p.x < min_x: min_x = p.x
		if p.y < min_y: min_y = p.y
		if p.x > max_x: max_x = p.x
		if p.y > max_y: max_y = p.y
	origin_curve_center = Vector2(round((max_x-min_x)/2+min_x), round((max_y-min_y)/2+min_y))
		
	bullet_origin.position = Vector2.ZERO
	bullet_prototype = load(bullet_scene)
	origin_follow = PathFollow2D.new()
	bullet_origin.add_child(origin_follow)
	var bullet_timing_total = CombatMgr.get_bullet_timing_total(bullet_timing)
	timing_accum_per_bullet = bullet_timing_total / num_bullets
	next_bullet_fired_at = timing_accum_per_bullet
	timing_accum = next_bullet_fired_at/2
	set_physics_process(false)

func start_attack():
	set_physics_process(true)

func _physics_process(delta):
	if curve_offset >= 100.0:
		set_physics_process(false)
		emit_signal("attack_complete")
	curve_offset += delta*100 / attack_time
	timing_accum += bullet_timing.interpolate(curve_offset/100.0) / attack_time
	while timing_accum >= next_bullet_fired_at:
		fire_bullet(curve_offset/100.0)
		next_bullet_fired_at += timing_accum_per_bullet

func fire_bullet(curve_offset):
	origin_follow.unit_offset = curve_offset
	var origin_pos = origin_follow.global_position - origin_curve_center
	var target_x = (bullet_target.interpolate(curve_offset) * target_width)
	var target_pos = global_target_point + Vector2(target_x, 0)
	var speed = bullet_speed.interpolate(curve_offset) * (max_speed - min_speed) + min_speed
	print("Firing at ", curve_offset, "; x=", target_x, "; speed=", speed)
	var bullet = bullet_prototype.instance()
	add_child(bullet)
	bullet.setup_bullet_motion(origin_pos, target_pos, speed)
