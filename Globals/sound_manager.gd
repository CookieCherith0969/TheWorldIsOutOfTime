extends Node

signal faded_out
signal faded_in

enum MusicFadeState {IDLE, FADE_IN, FADE_OUT}
enum MusicTracks {MENU, AMBIENT, EARLY, MIDDLE, LATE}

@onready
var menu_music : AudioStreamPlayer = $MenuMusic

@export
var music_tracks : Array[AudioStreamPlayer]

@export
var end_game_duration : int = 365
@export
var mid_game_duration : int = 365

const low_db : float = -80.0
const high_db : float = 0.0
var fade_time : float = 0.0
var fade_progress : float = 1.0
var music_fade_state : MusicFadeState = MusicFadeState.IDLE

var current_track : MusicTracks = MusicTracks.MENU

@export
var track_change_time : float = 100.0
@export
var track_change_variance : float = 20.0

func _process(delta: float) -> void:
	handle_fading(delta)
	

func handle_fading(delta : float):
	if music_fade_state == MusicFadeState.IDLE:
		return
	
	if music_fade_state == MusicFadeState.FADE_IN:
		fade_progress += delta/fade_time
		if fade_progress >= 1.0:
			fade_progress = 1.0
			music_fade_state = MusicFadeState.IDLE
			faded_in.emit()
		
	elif music_fade_state == MusicFadeState.FADE_OUT:
		fade_progress -= delta/fade_time
		if fade_progress <= 0.0:
			fade_progress = 0.0
			music_fade_state = MusicFadeState.IDLE
			faded_out.emit()
	
	var weight : float = in_out_sine_ease(fade_progress)
	var new_db : float = lerp(low_db, high_db, weight)
	
	AudioServer.set_bus_volume_db(1, new_db)

func in_out_sine_ease(progress : float):
	return -(cos(PI*progress) - 1) / 2

func fade_in_music(time : float):
	fade_time = time
	fade_progress = 0.0
	music_fade_state = MusicFadeState.FADE_IN

func fade_out_music(time : float):
	fade_time = time
	fade_progress = 1.0
	music_fade_state = MusicFadeState.FADE_OUT

func fade_to_track(time : float, to_track : MusicTracks):
	if to_track == current_track:
		return
	
	fade_out_music(time/3)
	await faded_out
	music_tracks[current_track].stop()
	await get_tree().create_timer(time/3).timeout
	music_tracks[to_track].play()
	current_track = to_track
	fade_in_music(time/3)

func get_menu_music_position() -> float:
	var time = menu_music.get_playback_position() + AudioServer.get_time_since_last_mix()
	# Compensate for output latency.
	time -= AudioServer.get_output_latency()
	return time

func get_menu_music_length() -> float:
	return menu_music.stream.get_length()

func get_menu_music_playback() -> AudioStreamPlayback:
	return menu_music.get_stream_playback()

func get_raw_menu_music_position() -> float:
	return menu_music.get_playback_position()

func get_menu_music_seconds() -> int:
	return roundi(menu_music.stream.get_length())
