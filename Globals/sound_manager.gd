extends Node

@onready
var menu_music : AudioStreamPlayer = $MenuMusic

@export
var end_game_duration : int = 365
@export
var mid_game_duration : int = 365

func start_menu_music():
	menu_music.play()

func stop_menu_music():
	menu_music.stop()

func get_menu_music_position() -> float:
	var time = menu_music.get_playback_position() + AudioServer.get_time_since_last_mix()
	# Compensate for output latency.
	time -= AudioServer.get_output_latency()
	return time
