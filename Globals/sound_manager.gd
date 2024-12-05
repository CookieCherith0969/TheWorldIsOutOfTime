extends Node

@onready
var menu_music : AudioStreamPlayer = $MenuMusic

@export
var end_game_duration : int = 365
@export
var mid_game_duration : int = 365

func start_menu_music():
	if !menu_music.playing:
		menu_music.play()

func start_game_music():
	pass


func get_menu_music_position() -> float:
	var time = menu_music.get_playback_position() + AudioServer.get_time_since_last_mix()
	# Compensate for output latency.
	time -= AudioServer.get_output_latency()
	return time

func get_menu_music_length() -> float:
	return menu_music.stream.get_length()

func get_menu_music_playback() -> AudioStreamPlayback:
	return menu_music.get_stream_playback()
