extends Node

export(int) var max_players_in_pool = 10

var players = []

func _ready():
	players.append(AudioStreamPlayer.new())

func play(stream_file, volume=0, pitch=1.0):
	var player:AudioStreamPlayer = get_first_free_player()
	player.pitch_scale = pitch
	player.volume_db = volume
	player.stream = load(stream_file)
	player.play()

func get_first_free_player():
	for player in players:
		if !player.playing:
			return player
	if players.size() >= max_players_in_pool:
		return players[0]
	var new_player = AudioStreamPlayer.new()
	players.add(new_player)
	return new_player
