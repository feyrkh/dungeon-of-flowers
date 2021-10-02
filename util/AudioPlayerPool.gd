extends Node

export(int) var max_players_in_pool = 10
var volume_adjustment = 0

var players = []

func _ready():
	get_first_free_player()
	volume_adjustment = Util.get_decibels_for_volume_percentage(GameData.get_setting(GameData.SFX_VOLUME, 100))
	GameData.listen_for_setting_change(self)

func on_setting_change(setting, old_val, new_val):
	if setting == GameData.SFX_VOLUME:
		volume_adjustment = Util.get_decibels_for_volume_percentage(new_val)
		for player in players:
			player.volume_db = volume_adjustment

func play(stream_file, pitch=1.0):
	var player:AudioStreamPlayer = get_first_free_player()
	player.pitch_scale = pitch
	player.volume_db = volume_adjustment
	if stream_file is String:
		player.stream = load(stream_file)
	else:
		player.stream = stream_file
	player.play()

func get_first_free_player():
	for player in players:
		if !player.playing:
			return player
	if players.size() >= max_players_in_pool:
		return players[0]
	var new_player = AudioStreamPlayer.new()
	players.append(new_player)
	add_child(new_player)
	return new_player
