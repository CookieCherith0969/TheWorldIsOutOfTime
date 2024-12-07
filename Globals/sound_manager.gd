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
var late_game_proportion : float = 1/3.0
@export
var mid_game_proportion : float = 1/3.0

const low_db : float = -80.0
const high_db : float = 0.0
var fade_time : float = 0.0
var fade_progress : float = 1.0
var music_fade_state : MusicFadeState = MusicFadeState.IDLE

var current_track : MusicTracks = MusicTracks.MENU

@export
var track_change_fade_time : float = 20.0
@export
var track_change_base : float = 100.0
@export
var track_change_variance : float = 20.0
var track_change_time : float = 0.0
var track_change_timer : float = 0.0
var track_changing : bool = false

var prev_day_proportion : float = 1.0

func _ready() -> void:
	track_change_time = track_change_base + randf_range(-track_change_variance, track_change_variance)
	GameManager.day_ended.connect(on_day_ended)

func on_day_ended():
	var day_proportion : float = float(GameManager.days_left)/GameManager.starting_days
	var mid_game_cutoff = late_game_proportion + mid_game_proportion
	
	if day_proportion < mid_game_cutoff && prev_day_proportion >= mid_game_cutoff:
		track_change_timer += track_change_time/2
	elif day_proportion < late_game_proportion && prev_day_proportion >= late_game_proportion:
		track_change_timer += track_change_time/2
	
	prev_day_proportion = day_proportion

func _process(delta: float) -> void:
	handle_fading(delta)
	handle_track_changing(delta)

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

func handle_track_changing(delta : float):
	if !track_changing:
		return
	if fade_progress < 1.0:
		return
	
	track_change_timer += delta
	
	if track_change_timer > track_change_time:
		track_change_timer = 0.0
		track_change_time = track_change_base + randf_range(-track_change_variance, track_change_variance)
		change_tracks()

func change_tracks():
	var day_proportion : float = float(GameManager.days_left)/GameManager.starting_days
	# Early game
	if day_proportion > late_game_proportion + mid_game_proportion:
		if current_track == MusicTracks.AMBIENT:
			fade_to_track(track_change_fade_time, MusicTracks.EARLY)
		else:
			fade_to_track(track_change_fade_time, MusicTracks.AMBIENT)
	# Mid game
	elif day_proportion > late_game_proportion:
		if current_track == MusicTracks.AMBIENT:
			fade_to_track(track_change_fade_time, MusicTracks.MIDDLE)
		else:
			fade_to_track(track_change_fade_time, MusicTracks.AMBIENT)
	# Late game
	else:
		if current_track == MusicTracks.AMBIENT:
			fade_to_track(track_change_fade_time, MusicTracks.LATE)
		else:
			fade_to_track(track_change_fade_time, MusicTracks.AMBIENT)

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
