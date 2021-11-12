extends Control

onready var AllyPortraits = find_node("AllyPortraits")

const SECONDS_TO_FADE_OUT = 0.1
const SECONDS_TO_FADE_IN = 0.75
const SECONDS_TO_DELAY_FADE = 1

const FADE_IN_ALPHA_PER_SECOND = 1.0 / SECONDS_TO_FADE_IN
const FADE_OUT_ALPHA_PER_SECOND = 1.0 / SECONDS_TO_FADE_OUT

var target_alpha = 1
var alpha = 0
var counter = SECONDS_TO_DELAY_FADE

func _ready():
	AllyPortraits.explore_mode()
	EventBus.connect("player_finish_move", self, "_on_move_finish")
	EventBus.connect("player_finish_turn", self, "_on_move_finish")
	EventBus.connect("player_start_move", self, "_on_move_start")
	EventBus.connect("player_start_turn", self, "_on_move_start")
	CombatMgr.connect("combat_start", self, "_on_combat_start")
	CombatMgr.connect("combat_end", self, "_on_combat_end")
	AllyPortraits.disable_combat_features()

func _on_combat_start():
	visible = false

func _on_combat_end():
	alpha = 0
	target_alpha = 0
	modulate.a = 0
	counter = SECONDS_TO_DELAY_FADE
	visible = true
	set_process(true)

func _on_move_finish():
	target_alpha = 1
	print("Finished move, target_alpha=", target_alpha)
	counter = SECONDS_TO_DELAY_FADE
	set_process(true)

func _on_move_start():
	target_alpha = 0
	print("Started move, target_alpha=", target_alpha)
	counter = 0
	set_process(true)

func _process(delta):
	if target_alpha == alpha:
		print("Finished fade, ", target_alpha, " == ", alpha)
		modulate.a = target_alpha
		set_process(false)
	if counter > 0:
		counter -= delta
		return
	if target_alpha > alpha:
		alpha = min(target_alpha, alpha + FADE_IN_ALPHA_PER_SECOND * delta)
	elif target_alpha < alpha:
		alpha = max(target_alpha, alpha - FADE_OUT_ALPHA_PER_SECOND * delta)
	modulate.a = alpha
	#print("modulate: ", modulate.a)
