extends Node2D

signal minigame_success(successAmount)
signal minigame_complete

const StackItem = preload("res://art_exports/ui_HUD/ui_HUD_icon_defend.png")

var started
var dropping = true
var side_speed = 100
var down_speed = 300

func _ready():
	yield(get_tree().create_timer(0.5), "timeout")
	if get_parent() == get_tree().root:
		start()

func start():
	if !GameData.get_state("ST_inst", false):
		EventBus.emit_signal("show_tutorial", "FirstTimeTooltip", true)
	started = true

func _process(delta):
	if !started: 
		return
	set_process(false)
	yield(get_tree().create_timer(2.5), "timeout")
	emit_signal("minigame_complete", self)

func set_minigame_config(game_config, source, target):
	pass
