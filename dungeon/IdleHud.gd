extends Control

onready var AllyPortraits = find_node("AllyPortraits")

const SECONDS_TO_FADE_OUT = 0.1
const SECONDS_TO_FADE_IN = 0.75
const SECONDS_TO_DELAY_FADE = 1

const FADE_IN_ALPHA_PER_SECOND = 1.0 / SECONDS_TO_FADE_IN
const FADE_OUT_ALPHA_PER_SECOND = 1.0 / SECONDS_TO_FADE_OUT

export var visible_when_chatting = false

var target_alpha = 1 setget set_target_alpha, get_target_alpha
var alpha = 0
var counter = SECONDS_TO_DELAY_FADE

func set_target_alpha(val):
	target_alpha = val

func get_target_alpha():
	if visible_when_chatting and ChatMgr.is_chatting():
		return 1.0
	return target_alpha

func _ready():
	if AllyPortraits: 
		AllyPortraits.explore_mode()
	EventBus.connect("player_finish_move", self, "_on_move_finish")
	EventBus.connect("player_finish_turn", self, "_on_move_finish")
	EventBus.connect("player_start_move", self, "_on_move_start")
	EventBus.connect("player_start_turn", self, "_on_move_start")
	CombatMgr.connect("combat_start", self, "_on_combat_start")
	CombatMgr.connect("combat_end", self, "_on_combat_end")
	if AllyPortraits: 
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
	#print("Finished move, target_alpha=", target_alpha)
	counter = SECONDS_TO_DELAY_FADE
	set_process(true)

func _on_move_start():
	target_alpha = 0
	#print("Started move, target_alpha=", target_alpha)
	counter = 0
	set_process(true)

func _process(delta):
	if get_target_alpha() == alpha:
		#print("Finished fade, ", target_alpha, " == ", alpha)
		modulate.a = get_target_alpha()
		set_process(false)
	if counter > 0:
		counter -= delta
		return
	if get_target_alpha() > alpha:
		alpha = min(get_target_alpha(), alpha + FADE_IN_ALPHA_PER_SECOND * delta)
	elif get_target_alpha() < alpha:
		alpha = max(get_target_alpha(), alpha - FADE_OUT_ALPHA_PER_SECOND * delta)
	modulate.a = alpha
	#print("modulate: ", modulate.a)
