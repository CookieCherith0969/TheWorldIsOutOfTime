extends Control

enum Screens {TITLE, GAME, END}

signal code_text_added(text : String)
signal mouse_used
signal ui_key_used
signal tooltip_shown
signal tooltip_hidden

@export
var current_screen_type : Screens = Screens.TITLE

@export
var tooltip : Tooltip
const tooltip_hold_time : float = 1
const tooltip_fade_time : float = 1

@export
var survival_backgrounds : Array[Texture]
@export
var destruction_backgrounds : Array[Texture]

const simplification_suffixes = [
	"",
	"K",
	"M",
	"B",
	"T",
	"Q"
]
const round_up_leniency = 0.025

var current_screen : Control
@export
var screen_scenes : Array[PackedScene]

var cursor_frame : int = 0
@export
var cursor_frames : Array[Texture]

@export
var fade_time : float = 4.0
@onready
var fade_component : FadeComponent = $FadeComponent

var empty_screen : Control

var focus_target : Control = self

@export
var palette_blue : Color
@export
var palette_white : Color
@export
var palette_grey : Color
@export
var palette_black : Color
@export
var palette_green : Color
@export
var palette_dark_blue : Color
@export
var palette_red : Color

var ui_actions : Array[String] = [
	"ui_accept",
	"ui_focus_next",
	"ui_focus_prev",
	"ui_left",
	"ui_right",
	"ui_up",
	"ui_down"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	empty_screen = get_tree().current_scene
	get_window().min_size = get_viewport().size
	make_new_screen(false)
	for ui_action in ui_actions:
		for event in InputMap.action_get_events(ui_action):
			if event is not InputEventKey:
				continue
			var shift_event : InputEventKey = event.duplicate()
			var ctrl_event : InputEventKey = event.duplicate()
			var shift_ctrl_event : InputEventKey = event.duplicate()
			
			shift_event.shift_pressed = true
			ctrl_event.ctrl_pressed = true
			shift_ctrl_event.shift_pressed = true
			shift_ctrl_event.ctrl_pressed = true
			
			InputMap.action_add_event(ui_action, shift_event)
			InputMap.action_add_event(ui_action, ctrl_event)
			InputMap.action_add_event(ui_action, shift_ctrl_event)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index < 3:
			mouse_used.emit()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cursor_frame -= 1
			cursor_frame %= cursor_frames.size()*2
		else:
			cursor_frame += 1
			cursor_frame %= cursor_frames.size()*2
		
		Input.set_custom_mouse_cursor(cursor_frames[cursor_frame/2])
		return
	
	for action in ui_actions:
		if event.is_action_pressed(action):
			ui_key_used.emit()
			return
	
	#if event.is_action_pressed("FixFocus"):
	#	focus_target.grab_focus()

func set_focus_target(target : Control):
	focus_target = target

func simplify_number(num : int, show_positive : bool = false) -> String:
	var plus_string = ""
	if num >= 0 && show_positive:
		plus_string = "+"
	
	if num == 0:
		return plus_string + "0"
	
	var magnitude : int = int(log(abs(num)+1) / log(10))
	var suffix_index = min(magnitude/3, simplification_suffixes.size()-1)
	
	var simplified_num : float = num/float(pow(1000,suffix_index))
	var truncated_num : float = simplified_num * 10
	truncated_num = floorf(truncated_num)
	truncated_num /= 10
	
	var num_string = ""
	if suffix_index <= 0:
		num_string = str(truncated_num)
	else:
		num_string = "%.01f" % truncated_num
	
	return plus_string + num_string + simplification_suffixes[suffix_index]

func show_build_tooltip(pos : Vector2i, materials : Array[GameManager.Materials], amounts : Array[int], time_cost : int = 0):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_build_header()
	tooltip.populate_costs(materials, amounts)
	if time_cost > 0:
		tooltip.add_time_cost(time_cost)
	tooltip.show_tooltip()
	tooltip_shown.emit()
	
func show_unlock_tooltip(pos : Vector2i, materials : Array[GameManager.Materials], amounts : Array[int], time_cost : int = 0):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_unlock_header()
	tooltip.populate_costs(materials, amounts)
	if time_cost > 0:
		tooltip.add_time_cost(time_cost)
	tooltip.show_tooltip()
	tooltip_shown.emit()

func show_material_tooltip(pos : Vector2i, represented_material : GameManager.Materials):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_material_header(represented_material)
	tooltip.populate_rates(represented_material)
	tooltip.show_tooltip()
	tooltip_shown.emit()

func show_rocket_tooltip(pos : Vector2i, materials : Array[GameManager.Materials], amounts : Array[int]):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_rocket_header()
	tooltip.populate_costs(materials, amounts)
	tooltip.show_tooltip()
	tooltip_shown.emit()

func show_time_tooltip(pos : Vector2i):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_header_icon(tooltip.time_icon, str(GameManager.days_left)+" days")
	tooltip.show_tooltip()
	tooltip_shown.emit()

func hide_tooltip():
	tooltip.hide_tooltip()
	tooltip_hidden.emit()

func fade_tooltip():
	tooltip.begin_fade(tooltip_hold_time, tooltip_fade_time)

func move_to_screen(new_screen : Screens):
	current_screen_type = new_screen
	make_new_screen()

func make_new_screen(fade : bool = true):
	if fade_component.fade_state != FadeComponent.FadeState.IDLE:
		return
	
	empty_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	if fade:
		match(current_screen_type):
			Screens.GAME:
				SoundManager.track_changing = true
				SoundManager.change_tracks()
			Screens.TITLE: 
				SoundManager.fade_to_track(fade_time, SoundManager.MusicTracks.MENU)
				SoundManager.track_changing = false
			Screens.END:
				SoundManager.track_changing = false
				if GameManager.game_state == GameManager.GameState.END_SURVIVAL:
					SoundManager.fade_to_track(fade_time, SoundManager.MusicTracks.EARLY)
				else:
					SoundManager.fade_to_track(fade_time, SoundManager.MusicTracks.AMBIENT)
		
		focus_mode = FOCUS_ALL
		grab_focus()
		focus_mode = FOCUS_NONE
		release_focus()
		fade_out(fade_time/3)
		await fade_component.fade_out_finished
	
	if is_instance_valid(current_screen):
		remove_child(current_screen)
		current_screen.queue_free()
	
	match(current_screen_type):
		Screens.GAME:
			GameManager.game_state = GameManager.GameState.TUTORIAL
			GameManager.timeskip_days = 0
			GameManager.reset_game()
			GameManager.paused = true
		Screens.TITLE:
			GameManager.game_state = GameManager.GameState.MENU
	
	var new_screen = screen_scenes[current_screen_type].instantiate()
	add_child(new_screen)
	current_screen = new_screen
	
	if fade:
		await get_tree().create_timer(fade_time/3).timeout
		fade_in(fade_time/3)
		await fade_component.fade_in_finished
	GameManager.paused = false
	empty_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if current_screen_type == Screens.END:
		current_screen.start_playing()

func fade_out(time : float):
	fade_component.fade_out(time)

func fade_in(time : float):
	fade_component.fade_in(time)

func print_to_code_window(text : String):
	code_text_added.emit(text)
