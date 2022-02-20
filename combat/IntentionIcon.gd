extends Sprite

const AttackBullet = preload("res://combat/AttackBullet.tscn")

const DAMAGE_MULTIPLIER_PER_THREAT_LEVEL = 0.1

const INTENTION_ATTACK_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_fight.png"
const INTENTION_DEFEND_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_defend.png"
const INTENTION_UNKNOWN_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_item.png"

const ATTACK_PERIOD_SECONDS = 4.0
const BULLET_REACH_TARGET_CENTER_SECONDS = 3.0
const BULLET_LIFE_SECONDS = ATTACK_PERIOD_SECONDS + BULLET_REACH_TARGET_CENTER_SECONDS
const MAX_MULTIPLIER = 6
var enemy
var intention
var attacking = false

var base_damage

var origin
var target
var allies
var enemies
var bullet_patterns
var bullet_pattern_scenes
var bullet_multipliers = []
var current_attack_scene

onready var BulletOrigin = find_node("BulletOrigin")

func _ready():
	CombatMgr.connect("execute_combat_intentions", self, "on_execute_combat_intentions")
	set_process(false)

func setup(_enemy, _intention):
	self.allies = CombatMgr.combat.combat_data.allies
	self.enemy = _enemy
	self.intention = _intention
	var intention_texture = INTENTION_UNKNOWN_IMG
	match intention.get("type"):
		"attack":
			intention_texture = INTENTION_ATTACK_IMG
			base_damage = intention.get("base_damage", 0.5) * (1 + GameData.get_threat_level()*DAMAGE_MULTIPLIER_PER_THREAT_LEVEL)
			bullet_patterns = intention.get("bullet_pattern", "slime/dribble")
			if bullet_patterns is String:
				bullet_patterns = [bullet_patterns]
		"defend":
			intention_texture = INTENTION_DEFEND_IMG
	visible = true
	texture = load(intention_texture)

func select_target():
	if allies.size() <= 0:
		target = null
		return
	var ally = allies[randi()%allies.size()]
	if intention.get("force_target") != null:
		ally = allies[intention.get("force_target")]
	print(enemy.data.label, " targeting ", ally.data.label)
	target = ally.rect_global_position + Vector2(50, 0) #ally.get_target(target_scatter)

func on_execute_combat_intentions(_allies, _enemies):
	print(self, ": Executing intention: ", intention)
	self.add_to_group("bullets")
	match intention.get("type"):
		"attack":
			perform_attacks(_allies, _enemies)


func perform_attacks(_allies, _enemies):
	attacking = true
	self.allies = _allies
	self.enemies = _enemies
	select_target()
	if !target:
		return
	var num_attack_repetitions = ceil(enemy.data.group_count / float(MAX_MULTIPLIER))
	var group_residue = enemy.data.group_count
	bullet_multipliers = []
	bullet_pattern_scenes = []
	for j in range(num_attack_repetitions):
		for i in range(bullet_patterns.size()):
			var pattern_scene = bullet_patterns[i]
			if !pattern_scene:
				continue
			pattern_scene = load("res://combat/patterns/%s.tscn" % pattern_scene)
			if !pattern_scene:
				continue
			pattern_scene = pattern_scene.instance()
			if !pattern_scene:
				continue
			bullet_pattern_scenes.append(pattern_scene)
			pattern_scene.num_bullets *= min(group_residue, MAX_MULTIPLIER)
		group_residue -= MAX_MULTIPLIER
	perform_next_attack()

func perform_next_attack():
	var next_scene = bullet_pattern_scenes.pop_front()
	var next_multiplier = bullet_multipliers.pop_front()
	if !enemy.is_alive() or !next_scene:
		attacking = false
		self.remove_from_group("bullets")
		return
	current_attack_scene = next_scene
	current_attack_scene.setup(base_damage, target, 400)
	BulletOrigin.add_child(current_attack_scene)
	current_attack_scene.start_attack()
	current_attack_scene.connect("attack_complete", self, "finish_current_attack")

func finish_current_attack():
	Util.delay_call(30, current_attack_scene, "queue_free")
	Util.delay_call(1, self, "perform_next_attack")

