extends Node

var allies = []
var world_tile_position = Vector2()
var facing = "north"
var settings_file = "user://settings.save"

var settings = { # default settings go here
	"music_volume": 1.0
}

func _ready():
	EventBus.connect("new_player_location", self, "on_new_player_location")
	new_game()
	load_settings()

func save_settings():
	var f = File.new()
	f.open(settings_file, File.WRITE)
	f.store_var(settings)
	f.close()

func load_settings():
	var f = File.new()
	if f.file_exists(settings_file):
		f.open(settings_file, File.READ)
		settings = f.get_var()
		f.close()

func update_setting(setting, val):
	settings[setting] = val

func get_setting(setting):
	return settings.get(setting)

func on_new_player_location(x, y, rot_deg):
	world_tile_position = Vector2(x, y)
	match int(round(rot_deg)):
		0: facing = "north"
		-90: facing = "east"
		180,-180: facing = "south"
		90: facing = "west"
		_: printerr("Unknown facing with angle ", int(round(rot_deg)))

func new_game():
	allies = [mock_pharoah(), mock_vega(), mock_shantae()]

func mock_pharoah():
	var ally = AllyData.new()
	ally.label = "Imhotep"
	ally.className = "Pharoah"
	ally.max_hp = 100
	ally.hp = 80
	ally.sp = 20
	ally.max_sp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero1.png")
	ally.moves = [
		MoveList.get_move('kick'),
		MoveList.get_move('headbutt'),
		
	]
	return ally

func mock_shantae():
	var ally = AllyData.new()
	ally.label = "Shantae"
	ally.className = "Half Genie"
	ally.max_hp = 100
	ally.hp = 80
	ally.sp = 20
	ally.max_sp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero3.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('kick')
	]
	return ally
	
func mock_vega():
	var ally = AllyData.new()
	ally.label = "Vega"
	ally.className = "Street Fighter"
	ally.max_hp = 100
	ally.hp = 80
	ally.sp = 20
	ally.max_sp = 20
	ally.balance = 100
	ally.max_balance = 100
	ally.texture = load("res://img/hero4.jpg")
	ally.moves = [
		MoveList.get_move('punch'),
		MoveList.get_move('kick'),
		MoveList.get_move('headbutt'),
	]
	return ally
