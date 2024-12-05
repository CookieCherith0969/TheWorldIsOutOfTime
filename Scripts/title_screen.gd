extends Control


const time_offset = 0.0
var registered_time : float = time_offset
var unregistered_time : float = 0.0
var registered_seconds : int = 0
var previous_time : float = 0.0

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
var slow_button : TextureButton = $ControlBox/SlowButton
@onready
var fast_button : TextureButton = $ControlBox/FastButton
@onready
var play_button : TextureButton = $MenuBox/PlayButton
@onready
var exit_button : TextureButton = $MenuBox/ExitButton

const max_speed : int = 16
const control_disabled_length : float = 0.1

@export
var planet_lifter : LiftManager
@export
var menu_lifter : LiftManager

func _ready():
	play_button.grab_focus()
	if OS.has_feature("web"):
		menu_box.remove_child(exit_button)
		exit_button.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
	menu_lifter.begin_lift()
	for button in menu_box.get_children():
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = true

func show_menu():
	#title.show()
	#menu_box.show()
	menu_lifter.begin_fall()
	await menu_lifter.fall_complete
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
	
	planet_lifter.begin_lift()
	await planet_lifter.lift_complete
	
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
	
	planet_lifter.begin_fall()
	await planet_lifter.fall_complete
	
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
	UIManager.current_screen_type = UIManager.Screens.GAME
	UIManager.make_new_screen()

func _on_settings_button_pressed() -> void:
	pass # Replace with function body.

func _on_exit_button_pressed() -> void:
	get_tree().quit()
