extends Node2D

signal all_damage_applied

const DamageIndicatorSlash = preload("res://combat/DamageIndicatorSlash.tscn")
const SINK_SPEED = 20
const FADE_SECONDS = 4

export(NodePath) var slash_target_path
export(Vector2) var target_extents

var slash_target
var ally_data

onready var DamageLabel:Label = find_node("Label")
onready var SlashContainer = find_node("SlashContainer")
onready var Player = find_node("AnimationPlayer")
onready var default_y = position.y

var accumulated_damage = 0

func _ready():
	reset()
	slash_target = get_node(slash_target_path)

func _process(delta):
	if DamageLabel.modulate.a > 0:
		DamageLabel.modulate.a -= delta/FADE_SECONDS
	if self.position.y != default_y:
		self.position.y = min(self.position.y + SINK_SPEED*delta, default_y)
	if DamageLabel.modulate.a <= 0 and self.position.y <= default_y:
		reset()

func reset():
	accumulated_damage = 0
	DamageLabel.visible = false
	set_process(false)
	Util.delete_children(SlashContainer)
	if ally_data:
		ally_data.round_stats()

func take_damage(amt):
	print("Adding damage slash: ", amt)
	var slash = DamageIndicatorSlash.instance()
	SlashContainer.add_child(slash)
	slash.global_position = slash_target.global_position + Vector2(rand_range(-target_extents.x, target_extents.x), rand_range(-target_extents.y, target_extents.y))
	slash.rotation_degrees = rand_range(0, 360)
	slash.set_damage(amt)

func apply_damage(_ally_data):
	var damage_total = 0
	self.ally_data = _ally_data
	for slash in SlashContainer.get_children():
		damage_total = slash.damage
		slash.apply_damage(ally_data, self, randf()*0.5 + 0.1)
		CombatMgr.emit_signal("combat_animation", 0.6)
	while SlashContainer.get_children().size() > 0:
		yield(get_tree().create_timer(0.1), "timeout")
		CombatMgr.emit_signal("combat_animation", 0.3)
	ally_data.hp = round(ally_data.hp)
	set_process(true)
	while CombatMgr.combat_animation_delay > 0:
		yield(get_tree().create_timer(CombatMgr.combat_animation_delay), "timeout")
	emit_signal("all_damage_applied", damage_total)

func count_damage(amt):
	DamageLabel.visible = true
	self.position.y -= 5
	DamageLabel.modulate.a = 1.0
	accumulated_damage += amt
	DamageLabel.text = "-"+str(round(accumulated_damage))+" hp"
