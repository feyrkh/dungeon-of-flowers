extends Node2D
class_name EffectBubble

var source_data
var source_node
var target_data # AllyData/EnemyData
var target_node # AllyCombatDisplay/Enemy
var min_position
var max_position
var circuit_time = 30.0
var effect
var effect_timer = 1

func _ready():
	$Tween.start()

func _process(delta):
	position.x = lerp(min_position.x, max_position.x, fmod(OS.get_system_time_msecs()/1000.0, circuit_time)/circuit_time)
	position.y = lerp(min_position.y, max_position.y, sin(OS.get_system_time_msecs()/1000.0/circuit_time*9.5))

func effect_setup(_effect, _source_data, _source_node, _target_data, _target_node):
	source_data = _source_data
	target_data = _target_data
	source_node = _source_node
	target_node = _target_node
	self.effect = _effect
	CombatMgr.connect("enemy_dead", self, "check_source_dead")
	if target_data is AllyData:
		CombatMgr.connect("decrement_ally_effect_timer", self, "decrement_effect_timer")
	else:
		CombatMgr.connect("decrement_enemy_effect_timer", self, "decrement_effect_timer")
	# TODO: Connect to an ally_dead signal when one exists

func decrement_effect_timer():
	effect_timer -= 1
	if effect_timer <= 0:
		end_effect()

func bubble_setup(_apply_buffs_on_combat_stage, _min_position, _max_position):
	self.min_position = _min_position
	self.max_position = _max_position
	#$Tween.interpolate_property(self, "position:x", min_position.x, max_position.x, circuit_time)
	#$Tween.interpolate_property(self, "position:y", min_position.y, max_position.y, circuit_time/9.5)
	CombatMgr.connect(_apply_buffs_on_combat_stage, self, "apply_effect")

func check_source_dead(_enemy):
	if !effect.effect_outlives_source and !is_instance_valid(source_node):
		end_effect()

func apply_effect():
	check_source_dead(source_node)
	effect.apply_effect_single_target(source_data, source_node, target_data, target_node)

func end_effect():
	queue_free()

func _on_Area2D_body_entered(bullet:Node2D):
	bullet.shield_block(self, 10000)
	end_effect()
	EventBus.emit_signal("refresh_bonus_icons")
