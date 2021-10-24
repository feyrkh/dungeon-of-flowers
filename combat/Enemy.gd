extends Node2D
class_name Enemy

const Weakspot = preload("res://combat/Weakspot.tscn")
const DamageFloater = preload("res://combat/DamageFloater.tscn")
const MAX_FOLLOWER_COUNT = 6

onready var IntentionIcon = find_node("IntentionIcon")

var data : EnemyData
var intention
var spread_factor = 1.0

func _ready():
	if !data:
		data = EnemyData.new("Puddle", 30, preload("res://art_exports/characters/enemy_puddle.png"))
	$Sprite.texture = data.img
	$DamageIndicator.connect("all_damage_applied", self, "_on_all_damage_applied")
	$Sprite.set_material($Sprite.get_material().duplicate(true))
	$Tween.start()

func setup(_data:EnemyData, _spread_factor=1.0):
	self.data = _data
	self.spread_factor = _spread_factor
	if data.group_count < 1:
		data.group_count = 1
	setup_group()

const PLACEMENTS = [
	{"pos": Vector2(0, 0), "color": Color(1, 1, 1), "fade_delay": 0.01},
	{"pos": Vector2(50, -60), "color": Color(0.4, 0.4, 0.4), "fade_delay": 0.5},
	{"pos": Vector2(-50, -60), "color": Color(0.4, 0.4, 0.4), "fade_delay": 0.5},
	{"pos": Vector2(0, -120), "color": Color(0.1, 0.1, 0.1), "fade_delay": 1.0},
	{"pos": Vector2(-100, -120), "color": Color(0.1, 0.1, 0.1), "fade_delay": 1.0},
	{"pos": Vector2(100, -120), "color": Color(0.1, 0.1, 0.1), "fade_delay": 1.0}
]

func setup_group():
	var placed = 0
	var rank = 1
	for i in range (0, min(data.group_count, PLACEMENTS.size())):
		add_follower(i)

func add_follower(placement_pos):
		var follower = Sprite.new()
		follower.texture = data.img	
		follower.set_material($Sprite.get_material().duplicate(true))
		follower.modulate = Color.transparent
		$Followers.add_child(follower)
		follower.position = PLACEMENTS[placement_pos].get("pos") + Vector2(PLACEMENTS[placement_pos].get("pos").x * spread_factor, 0) + Vector2(randf()*2-1, randf()*2-1)
		$Tween.interpolate_property(follower, "modulate", Color(0, 0, 0, 0), PLACEMENTS[placement_pos].color, PLACEMENTS[placement_pos].fade_delay, 
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.interpolate_property(follower, "position", follower.position - Vector2(rand_range(-30, 30), 50), follower.position, PLACEMENTS[placement_pos].fade_delay,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
		CombatMgr.emit_signal("combat_animation", PLACEMENTS[placement_pos].fade_delay)
		
func is_alive():
	return data.hp > 0

func damage_hp(amt):
	# TODO: accumulate damage here instead of doing direct damage
	#self.data.hp -= amt
	#print(data.label + " has "+str(data.hp)+" hp left")
	$DamageIndicator.take_damage(amt)
	var floater = DamageFloater.instance()
	floater.set_damage(round(amt))
	add_child(floater)

func _on_all_damage_applied(amt):
	if amt > 0:
		Util.shake(self, 0.2, 20, self, "check_death")
		
func apply_damage():
	$DamageIndicator.apply_damage(data)

func decide_enemy_action():
	intention = data.get_next_intention()
	IntentionIcon.setup(self, intention)

func check_death():
	$Tween.remove_all()
	if data.dead_followers > 0:
		var empty_positions = []
		var brightness = []
		for i in range(min(data.dead_followers, $Followers.get_child_count())):
			var sprite = $Followers.get_child(i)
			empty_positions.append(sprite.position)
			brightness.append(sprite.modulate)
			destroy_sprite(sprite, i)
		
		var cur_pos = data.dead_followers
		while cur_pos < MAX_FOLLOWER_COUNT and cur_pos < $Followers.get_child_count() and empty_positions.size() > 0:
			var sprite = $Followers.get_child(cur_pos)
			cur_pos += 1
			if !sprite: continue
			var new_pos = empty_positions.pop_front()
			var new_brightness = brightness.pop_front()
			empty_positions.append(sprite.position)
			brightness.append(sprite.modulate)
			$Tween.interpolate_property(sprite, "position", sprite.position, new_pos, 0.5)
			$Tween.interpolate_property(sprite, "modulate", sprite.modulate, new_brightness, 0.5)
			CombatMgr.emit_signal("combat_animation", 0.5)
		
		var already_existing_children = max(0, $Followers.get_child_count() - data.dead_followers)
		if already_existing_children < data.group_count:
			for i in min(data.group_count - already_existing_children, empty_positions.size()):
				if i + already_existing_children >= MAX_FOLLOWER_COUNT: 
					break
				add_follower(i + already_existing_children)
	
		data.dead_followers = 0
		Util.delay_call($Sprite.material.get_shader_param("duration")+0.85, $Tween, "start")
		CombatMgr.emit_signal("combat_animation", $Sprite.material.get_shader_param("duration")+0.85+0.5)
	if self.data.hp <= 0:
		die()

func die():
	find_node("IntentionIcon").visible = false
	while CombatMgr.combat_animation_delay > 0:
		yield(get_tree().create_timer(CombatMgr.combat_animation_delay), "timeout")
	queue_free()
	CombatMgr.emit_signal("enemy_dead", self)

func destroy_sprite(sprite, sprites_destroyed):
	sprite.material.set_shader_param("start_time", OS.get_ticks_msec() / 1000.0 + sprites_destroyed*0.2)
	CombatMgr.emit_signal("combat_animation", sprite.material.get_shader_param("duration")+0.5 + sprites_destroyed*0.2)
	Util.delay_call(sprite.material.get_shader_param("duration")+0.5, sprite, "queue_free")

func highlight():
	find_node("Pulser").start()

func unhighlight():
	find_node("Pulser").stop()


