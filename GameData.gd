extends Node

signal setting_updated(setting_name, old_value, new_value)
signal state_updated(state_name, old_value, new_value)

const MUSIC_VOLUME = "music_volume"
const SFX_VOLUME = "sfx_volume"
const TUTORIAL_ON = "tutorial_on"

var allies = []
var world_tile_position = Vector2()
var facing = "north"
var settings_file = "user://settings.save"

var settings = { # default settings go here
	MUSIC_VOLUME: 65,
	SFX_VOLUME: 65,
	TUTORIAL_ON: true
}

var game_state = {
	
}

func listen_for_setting_change(listener):
	connect("setting_updated", listener, "on_setting_change")

func _ready():
	EventBus.connect("new_player_location", self, "on_new_player_location")
	new_game()
	load_settings()

func save_settings():
	var f = File.new()
	var err = f.open(settings_file, File.WRITE)
	if err != 0:
		printerr(settings_file, " : Failed to open settings file while saving, got error: ", err)
		return
	f.store_var(settings)
	f.close()

func load_settings():
	var f = File.new()
	if f.file_exists(settings_file):
		var err = f.open(settings_file, File.READ)
		if err != 0:
			printerr(settings_file, " : Failed to open settings file while loading, got error: ", err)
			return
		var new_settings:Dictionary = f.get_var()
		f.close()
		for setting in new_settings.keys():
			update_setting(setting, new_settings[setting])

func update_setting(setting, val):
	var old_value = settings.get(setting, null)
	settings[setting] = val
	if old_value != val:
		emit_signal("setting_updated", setting, old_value, val)
		print("Setting ", setting, "=", val)

func set_setting(setting, val):
	update_setting(setting, val)

func get_setting(setting, defaultVal=null):
	return settings.get(setting, defaultVal)

func get_state(state_entry, default_val=null):
	return game_state.get(state_entry, default_val)

func set_state(state_entry, val):
	update_state(state_entry, val)

func update_state(state_entry, val):
	var old_value = game_state.get(state_entry, null)
	game_state[state_entry] = val
	if old_value != val:
		emit_signal("state_updated", state_entry, old_value, val)
		print("State ", state_entry, "=", val)

func on_new_player_location(x, y, rot_deg):
	world_tile_position = Vector2(x, y)
	match int(round(rot_deg)):
		0: facing = "north"
		-90: facing = "east"
		180,-180: facing = "south"
		90: facing = "west"
		_: printerr("Unknown facing with angle ", int(round(rot_deg)))

func new_game():
	if get_setting(TUTORIAL_ON):
		allies = [null, mock_vega(), null]
	else:
		allies = [mock_pharoah(), mock_vega(), mock_shantae()]

func mock_pharoah():
	var ally = AllyData.new()
	ally.label = "Imhotep"
	ally.className = "Pharoah"
	ally.max_hp = 100
	ally.hp = 100
	ally.sp = 20
	ally.max_sp = 20
	ally.texture = load("res://img/hero1.png")
	ally.moves = [
		MoveList.get_move('kick'),
		MoveList.get_move('headbutt'),
	]
	ally.shields = [
		{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(0, -130), "scale": Vector2(0.5, 0.5)},
	]
	return ally

func mock_shantae():
	var ally = AllyData.new()
	ally.label = "Shantae"
	ally.className = "Half Genie"
	ally.max_hp = 100
	ally.hp = 100
	ally.sp = 20
	ally.max_sp = 20
	ally.texture = load("res://img/hero3.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('kick')
	]
	ally.shields = [
		{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(0, -130), "scale": Vector2(1.0, 1.0)},
	]
	return ally
	
func mock_vega():
	var ally = AllyData.new()
	ally.label = "Vega"
	ally.className = "Street Fighter"
	ally.max_hp = 100
	ally.hp = 100
	ally.sp = 20
	ally.max_sp = 20
	ally.texture = load("res://img/hero4.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('kick'),
		MoveList.get_move('headbutt'),
	]
	ally.shields = [
		{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(-150, -130), "scale": Vector2(2.0, 1.0)},
		{"scene":"res://combat/ShieldHard.tscn", "pos": Vector2(150, -130), "scale": Vector2(2.0, 1.0)},
	]
	return ally
