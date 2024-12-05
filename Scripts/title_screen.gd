extends Control

const time_offset = 0.0
var registered_time : float = time_offset
var unregistered_time : float = 0.0
var registered_seconds : int = 0
var previous_time : float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var current_time = SoundManager.get_menu_music_position()
	var time_diff = current_time - previous_time
	unregistered_time += time_diff
	if unregistered_time - registered_time >= 1.0:
		registered_time += 1.0
		registered_seconds += 1
		registered_seconds %= 43200
		unregistered_time -= 1.0
	
	previous_time = current_time

func update_clock_hands():
	var seconds_passed = registered_seconds
	
	var hours_passed = seconds_passed / 3600
	seconds_passed -= hours_passed * 3600
	
	var minutes_passed = seconds_passed / 60
	seconds_passed -= minutes_passed * 60
	
	
