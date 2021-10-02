extends Node

var MIN_VOLUME = -50
var MAX_VOLUME = 0

export(NodePath) var stream_player_1_path = "CombatMusic"
export(NodePath) var stream_player_2_path = "ExploreMusic"
export(float) var default_db
onready var cur_playing:AudioStreamPlayer = find_node(stream_player_1_path)
onready var next_playing:AudioStreamPlayer = find_node(stream_player_2_path)

var fade_counter:float = 0
var seconds_to_fade = 3
var fading = false
var music_positions = {}
var cur_playing_file = ""
var next_playing_file
var fade_up_per_sec = 0
var fade_down_per_sec = 0

var volume_adjustment = 0
var expected_next_volume = 0
var expected_cur_volume = 0

func _ready():
	volume_adjustment = GameData.get_setting(GameData.MUSIC_VOLUME, 100) / 100.0
	GameData.listen_for_setting_change(self)

func on_setting_change(setting, old_val, new_val):
	if setting == GameData.MUSIC_VOLUME:
		volume_adjustment = GameData.get_setting(GameData.MUSIC_VOLUME, 100) / 100.0
		set_next_volume(expected_next_volume)
		set_cur_volume(expected_cur_volume)
		#cur_playing.volume_db = Util.get_decibels_for_volume_percentage(new_val)

func cross_fade(new_music_file, crossfade_time, new_music_saves_position=true):
	if fading:
		swap_players()
	next_playing_file = new_music_file
	music_positions[cur_playing_file] = cur_playing.get_playback_position()
	fade_counter = crossfade_time
	next_playing.stop()
	next_playing.stream = load(new_music_file)
	set_next_volume(MIN_VOLUME)
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

#func _unhandled_input(event):
#	if event.is_action_pressed("music_toggle"):
#		get_tree().set_input_as_handled()
#		if volume_adjustment == 0: 
#			volume_adjustment = 100.0
#			cur_playing.volume_db = 0
#		else: 
#			volume_adjustment = 0
#			cur_playing.volume_db = -80
#		GameData.update_setting("music_volume", volume_adjustment)
#		GameData.save_settings()

func _process(delta):
	set_next_volume(min(MAX_VOLUME, expected_next_volume + fade_up_per_sec * delta))
	set_cur_volume(max(MIN_VOLUME, cur_playing.volume_db - fade_down_per_sec * delta))
	if expected_next_volume == MAX_VOLUME:
		music_positions[cur_playing_file] = cur_playing.get_playback_position()
		print("Crossfade finished, pausing ", cur_playing_file, " at ", cur_playing.get_playback_position())
		cur_playing.stop()
		swap_players()
		fading = false
		set_process(false)

func set_next_volume(amt):
	expected_next_volume = amt
	next_playing.volume_db = ((amt+60) * volume_adjustment)-60
	#print("Next volume: ", amt, " (actual: ", next_playing.volume_db, ")")

func set_cur_volume(amt):
	expected_cur_volume = amt
	cur_playing.volume_db = ((amt+60) * volume_adjustment)-60
	#print("Cur volume: ", amt, " (actual: ", cur_playing.volume_db, ")")

func swap_players():
	var tmp = cur_playing
	cur_playing = next_playing
	next_playing = tmp
	tmp = cur_playing_file
	cur_playing_file = next_playing_file
	next_playing_file = cur_playing_file
	tmp = expected_cur_volume
	expected_cur_volume = expected_next_volume
	expected_next_volume = tmp
