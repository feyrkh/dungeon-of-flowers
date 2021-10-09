extends Sprite

const AttackBullet = preload("res://combat/AttackBullet.tscn")

const INTENTION_ATTACK_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_fight.png"
const INTENTION_DEFEND_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_defend.png"
const INTENTION_UNKNOWN_IMG = "res://art_exports/ui_HUD/ui_HUD_icon_item.png"

const ATTACK_PERIOD_SECONDS = 4.0
const BULLET_REACH_TARGET_CENTER_SECONDS = 3.0
const BULLET_LIFE_SECONDS = ATTACK_PERIOD_SECONDS + BULLET_REACH_TARGET_CENTER_SECONDS

var enemy
var intention

var base_damage
var attacks
var attacks_per_pulse
var target_scatter
var target_change_chance # chance of switching targets after each pulse
var origin_scatter
var origin_change_chance # chance of switching origin location after each pulse

var seconds_per_bullet # seconds we should wait after firing a bullet
var bullet_time_counter # time elapsed since last bullet
var pulse_bullet_counter # number of bullets left in this pulse
var origin
var target
var allies
var enemies
var timeout

func _ready():
	CombatMgr.connect("execute_combat_intentions", self, "on_execute_combat_intentions")
	set_process(false)

func setup(_enemy, _intention):
	self.enemy = _enemy
	self.intention = _intention
	var intention_texture = INTENTION_UNKNOWN_IMG
	match intention.get("type"):
		"attack": 
			intention_texture = INTENTION_ATTACK_IMG
		"defend": 
			intention_texture = INTENTION_DEFEND_IMG
	visible = true
	texture = load(intention_texture)

func _process(delta):
	bullet_time_counter += delta
	timeout -= delta
	if timeout <= 0:
		self.remove_from_group("bullets")
	while bullet_time_counter >= seconds_per_bullet:
		bullet_time_counter -= seconds_per_bullet
		if attacks > 0:
			fire_bullet(bullet_time_counter)
		else:
			set_process(false)
			self.remove_from_group("bullets")
	

func fire_bullet(lag_time):
	if pulse_bullet_counter <= 0:
		pulse_bullet_counter = attacks_per_pulse
		select_origin()
		select_target()
	if target == null:
		return
	pulse_bullet_counter -= 1
	attacks -= 1
	var bullet = AttackBullet.instance()
	CombatMgr.emit_signal("new_bullet", bullet)
	bullet.setup(base_damage, self, origin, target, BULLET_REACH_TARGET_CENTER_SECONDS, BULLET_LIFE_SECONDS)
	if lag_time > 0:
		bullet._process(lag_time)

func select_origin():
	if (origin_change_chance > 0 and origin_change_chance > randf()) or (origin == null):
		origin = self.global_position
		if origin_scatter > 0:
			origin -= self.texture.get_size()/2
			origin += Vector2(randf()*origin_scatter*self.texture.get_size().x*scale.x, randf()*origin_scatter*self.texture.get_size().y*scale.y)

func select_target():
	if allies.size() <= 0:
		target = null
		return
	if (target_change_chance > 0 and target_change_chance > randf()) or (target == null):
		var ally = allies[randi()%allies.size()]
		if intention.get("force_target") != null:
			ally = allies[intention.get("force_target")]
		print(enemy.data.label, " targeting ", ally.ally_data.label)
		target = ally.get_target(target_scatter)

func on_execute_combat_intentions(_allies, _enemies):
	print(self, ": Executing intention: ", intention)
	self.add_to_group("bullets")
	match intention.get("type"):
		"attack": 
			perform_attack(_allies, _enemies)

func perform_attack(_allies, _enemies):
	self.allies = _allies
	self.enemies = _enemies
	base_damage = intention.get("base_damage", 0.5)
	attacks = intention.get("attacks", 1)
	attacks_per_pulse = max(1, intention.get("attacks_per_pulse", 1))
	target_scatter = intention.get("target_scatter", 0)
	target_change_chance = intention.get("target_change_chance", 1)
	origin_scatter = intention.get("origin_scatter", 0)
	origin_change_chance = intention.get("origin_change_chance", 0)
	
	seconds_per_bullet = max(0.01, ATTACK_PERIOD_SECONDS / attacks)
	bullet_time_counter = 0.0
	pulse_bullet_counter = 0
	origin = null
	target = null
	timeout = BULLET_LIFE_SECONDS+0.5
	set_process(true)
#		"base_damage": 0.5,
#		"attacks": 10,
#		"attacks_per_pulse": 1,
#		"target_scatter": 0,
#		"target_change_chance": 0.2,
#		"origin_scatter": 0,
#		"origin_change_chance": 1,
