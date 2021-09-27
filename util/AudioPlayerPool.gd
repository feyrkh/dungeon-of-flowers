extends Node

export(int) var max_players_in_pool = 10
const volume_reduction = 10

var players = []

func _ready():
	get_first_free_player()

func play(stream_file, volume=0, pitch=1.0):
	var player:AudioStreamPlayer = get_first_free_player()
	player.pitch_scale = pitch
	player.volume_db = volume - volume_reduction
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
