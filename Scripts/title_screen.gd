extends Control


const time_offset = 0.0
var registered_time : float = time_offset
var unregistered_time : float = 0.0
var registered_seconds : int = 0
var previous_time : float = 0.0
var previous_raw_time : float = 0.0

@export
var second_hand_length : float = 30.0
@export
var minute_hand_length : float = 24.0
@export
var hour_hand_length : float = 18.0
@export
var second_hand : Line2D
@export
var minute_hand : Line2D
@export
var hour_hand : Line2D

const seconds_per_minute : int = 60
const minutes_per_hour : int = 60
const hours_per_cycle : int = 12

var seconds_per_cycle : int = hours_per_cycle*minutes_per_hour*seconds_per_minute

@onready
var hide_button : TextureButton = $HideButton
@export
var hide_normal_open : Texture
@export
var hide_hover_open : Texture
@export
var hide_normal_closed : Texture
@export
var hide_hover_closed : Texture

var menu_hidden : bool = false

@onready
var title : TextureRect = $Title
@onready
var menu_box : HBoxContainer = $MenuBox
@onready
var control_box : HBoxContainer = $ControlBox
@onready
var settings_box : VBoxContainer = $SettingsBox
@onready
var slow_button : TextureButton = $ControlBox/SlowButton
@onready
var fast_button : TextureButton = $ControlBox/FastButton
@onready
var play_button : TextureButton = $MenuBox/PlayButton
@onready
var settings_button : TextureButton = $MenuBox/SettingsButton
@onready
var exit_button : TextureButton = $MenuBox/ExitButton

const max_speed : int = 16

@export
var planet_slider : SlideManager
@export
var menu_slider : SlideManager

@export
var settings_slider : SlideManager
@export
var settings_title_slider : SlideManager
@export
var settings_menu_slider : SlideManager

var settings_hidden : bool = true

func _ready():
	play_button.grab_focus()
	UIManager.set_focus_target(play_button)
	if OS.has_feature("web"):
		menu_box.remove_child(exit_button)
		exit_button.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	var current_time = SoundManager.get_menu_music_position()
	var raw_time = SoundManager.get_raw_menu_music_position()
	var time_diff = current_time - previous_time
	var raw_diff = raw_time - previous_raw_time
	#var playback : AudioStreamPlaybackOggVorbis = SoundManager.get_menu_music_playback()
	
	# Keeping within bounds to avoid too much error
	while registered_time > seconds_per_cycle:
		registered_time -= seconds_per_cycle
		unregistered_time -= seconds_per_cycle
	
	# Track looped
	if raw_diff < 0.0:
		unregistered_time = snappedf(unregistered_time, SoundManager.get_menu_music_seconds())
		registered_time = unregistered_time
		registered_seconds = int(registered_time)
		unregistered_time += current_time
		update_clock_hands()
		previous_time = current_time
		previous_raw_time = raw_time
		return
	
	unregistered_time += time_diff
	
	#while registered_time - unregistered_time >= 1.0:
	#	unregistered_time += 1.0
	
	while unregistered_time - registered_time >= 1.0:
		registered_time += 1.0
		registered_seconds += 1
		registered_seconds %= seconds_per_cycle
		
		update_clock_hands()
	
	previous_time = current_time
	previous_raw_time = raw_time

func update_clock_hands():
	var seconds_passed : int = registered_seconds
	
	var seconds_per_hour : int = minutes_per_hour*seconds_per_minute
	var hours_passed : int = seconds_passed / seconds_per_hour
	seconds_passed -= hours_passed * seconds_per_hour
	
	var minutes_passed : int = seconds_passed / seconds_per_minute
	seconds_passed -= minutes_passed * seconds_per_minute
	
	var second_ratio = float(seconds_passed)/seconds_per_minute
	var minute_ratio = float(minutes_passed)/minutes_per_hour
	var hour_ratio = float(hours_passed)/hours_per_cycle
	
	second_hand.points[1] = Vector2.UP.rotated(second_ratio*2*PI)*second_hand_length
	minute_hand.points[1] = Vector2.UP.rotated(minute_ratio*2*PI)*minute_hand_length
	hour_hand.points[1] = Vector2.UP.rotated(hour_ratio*2*PI)*hour_hand_length


func _on_hide_button_pressed() -> void:
	menu_hidden = !menu_hidden
	if menu_hidden:
		hide_menu()
		show_controls()
	else:
		show_menu()
		hide_controls()

func hide_menu():
	#title.hide()
	#menu_box.hide()
	menu_slider.slide_forward()
	for button in menu_box.get_children():
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = true

func show_menu():
	#title.show()
	#menu_box.show()
	menu_slider.slide_backward()
	await menu_slider.backward_complete
	for button in menu_box.get_children():
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = false

func show_controls():
	control_box.show()
	
	hide_button.texture_normal = hide_normal_closed
	hide_button.texture_hover = hide_hover_closed
	
	slow_button.disabled = true
	fast_button.disabled = true
	hide_button.disabled = true
	slow_button.get_child(0).trigger_hover()
	fast_button.get_child(0).trigger_hover()
	hide_button.get_child(0).active = true
	
	planet_slider.slide_forward()
	await planet_slider.forward_complete
	
	slow_button.disabled = false
	fast_button.disabled = false
	hide_button.disabled = false

func hide_controls():
	hide_button.texture_normal = hide_normal_open
	hide_button.texture_hover = hide_hover_open
	
	slow_button.disabled = true
	fast_button.disabled = true
	hide_button.disabled = true
	hide_button.get_child(0).active = false
	
	planet_slider.slide_backward()
	await planet_slider.backward_complete
	
	slow_button.disabled = false
	fast_button.disabled = false
	hide_button.disabled = false
	control_box.hide()

func _on_slow_button_pressed() -> void:
	GameManager.screensaver_speed_multiplier -= 1
	if GameManager.screensaver_speed_multiplier <= 0:
		GameManager.screensaver_speed_multiplier = 0
		slow_button.disabled = true
	else:
		slow_button.disabled = false
	fast_button.disabled = false

func _on_fast_button_pressed() -> void:
	GameManager.screensaver_speed_multiplier += 1
	if GameManager.screensaver_speed_multiplier >= max_speed:
		GameManager.screensaver_speed_multiplier = max_speed
		fast_button.disabled = true
	else:
		fast_button.disabled = false
	slow_button.disabled = false

func _on_play_button_pressed() -> void:
	UIManager.move_to_screen(UIManager.Screens.GAME)

func _on_settings_button_pressed() -> void:
	settings_hidden = !settings_hidden
	if settings_hidden:
		hide_settings()
		SettingsManager.save_settings()
	else:
		show_settings()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func hide_settings():
	settings_button.disabled = true
	hide_button.disabled = true
	for child in settings_box.get_children():
		if child is Slider:
			child.editable = false
		elif child is TextureButton:
			child.disabled = true
	
	settings_slider.slide_backward()
	settings_menu_slider.slide_backward()
	settings_title_slider.slide_backward()
	await settings_slider.backward_complete
	
	settings_button.disabled = false
	hide_button.disabled = false
	for child in settings_box.get_children():
		if child is Slider:
			child.editable = true
		elif child is TextureButton:
			child.disabled = false

func show_settings():
	settings_button.disabled = true
	hide_button.disabled = true
	for child in settings_box.get_children():
		if child is Slider:
			child.editable = false
		elif child is TextureButton:
			child.disabled = true
			
	settings_slider.slide_forward()
	settings_menu_slider.slide_forward()
	settings_title_slider.slide_forward()
	await settings_slider.forward_complete
	
	settings_button.disabled = false
	hide_button.disabled = false
	for child in settings_box.get_children():
		if child is Slider:
			child.editable = true
		elif child is TextureButton:
			child.disabled = false
