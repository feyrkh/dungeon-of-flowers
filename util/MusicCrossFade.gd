extends Node

const MIN_VOLUME = -50
const MAX_VOLUME = 0

export(NodePath) var stream_player_1_path = "CombatMusic"
export(NodePath) var stream_player_2_path = "ExploreMusic"
export(float) var default_db
onready var cur_playing:AudioStreamPlayer = find_node(stream_player_1_path)
onready var next_playing:AudioStreamPlayer = find_node(stream_player_2_path)

var fade_counter = 0
var seconds_to_fade = 3
var fading = false
var music_positions = {}
var cur_playing_file = ""
var next_playing_file
var fade_up_per_sec
var fade_down_per_sec

func _ready():
	pass

func cross_fade(new_music_file, crossfade_time, new_music_saves_position=true):
	if fading:
		swap_players()
	next_playing_file = new_music_file
	music_positions[cur_playing_file] = cur_playing.get_playback_position()
	fade_counter = crossfade_time
	next_playing.stop()
	next_playing.stream = load(new_music_file)
	next_playing.volume_db = MIN_VOLUME
	fade_up_per_sec = (MAX_VOLUME - MIN_VOLUME)/crossfade_time
	fade_down_per_sec = (cur_playing.volume_db - MIN_VOLUME)/crossfade_time
	var start_position = 0.0
	if new_music_saves_position:
		start_position = music_positions.get(new_music_file, 0.0)
		print("Resuming ", new_music_file, " at ", start_position)
	else:
		print("Resuming ", new_music_file, " from the beginning, always")
	next_playing.play(start_position)
	fading = true
	set_process(true)

func _process(delta):
	next_playing.volume_db = min(MAX_VOLUME, next_playing.volume_db + fade_up_per_sec * delta)
	cur_playing.volume_db = max(MIN_VOLUME, cur_playing.volume_db - fade_down_per_sec * delta)
	if next_playing.volume_db == MAX_VOLUME:
		music_positions[cur_playing_file] = cur_playing.get_playback_position()
		print("Crossfade finished, pausing ", cur_playing_file, " at ", cur_playing.get_playback_position())
		cur_playing.stop()
		swap_players()
		fading = false
		set_process(false)


func swap_players():
	var tmp = cur_playing
	cur_playing = next_playing
	next_playing = tmp
	tmp = cur_playing_file
	cur_playing_file = next_playing_file
	next_playing_file = cur_playing_file
