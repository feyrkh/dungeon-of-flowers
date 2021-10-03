extends Sprite

const ABSORB_SECONDS = 0.3

var damage_indicator
var ally_data
var damage = 0
var target
var speed
var delay
var move_counter = 0

func _ready():
	set_process(false)

func _process(delta):
	if delay > 0:
		delay -= delta
	else:
		move_counter += delta
		if move_counter > ABSORB_SECONDS:
			move_counter = -1000
			finish_damage()
			set_process(false)
		else:
			self.global_position += speed * delta

func finish_damage():
	ally_data.hp = ally_data.hp - damage
	damage_indicator.count_damage(damage)
	damage = 0
	queue_free()

func set_damage(amt):
	damage = amt

func apply_damage(_ally_data, _damage_indicator, _delay):
	set_process(true)
	self.ally_data = _ally_data
	self.damage_indicator = _damage_indicator
	self.delay = _delay
	self.target = _damage_indicator.DamageLabel.rect_global_position + _damage_indicator.DamageLabel.rect_size/2
	self.speed = (target - self.global_position) / ABSORB_SECONDS
