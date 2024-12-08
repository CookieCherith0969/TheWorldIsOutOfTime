extends Control

enum Screens {TITLE, GAME, END}

signal code_text_added(text : String)

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	empty_screen = get_tree().current_scene
	get_window().min_size = get_viewport().size
	make_new_screen(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DebugReset"):
		make_new_screen()
	if event.is_action_pressed("DebugFullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cursor_frame -= 1
			cursor_frame %= cursor_frames.size()*2
		else:
			cursor_frame += 1
			cursor_frame %= cursor_frames.size()*2
		
		Input.set_custom_mouse_cursor(cursor_frames[cursor_frame/2])
	
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
	
	var magnitude : int = int(log(abs(num)) / log(10) + round_up_leniency)
	var suffix_index = min(magnitude/3, simplification_suffixes.size()-1)
	
	var simplified_num : float = num/float(pow(1000,suffix_index))
	var truncated_num : float = snapped(simplified_num, 0.1)
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
	
func show_unlock_tooltip(pos : Vector2i, materials : Array[GameManager.Materials], amounts : Array[int], time_cost : int = 0):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_unlock_header()
	tooltip.populate_costs(materials, amounts)
	if time_cost > 0:
		tooltip.add_time_cost(time_cost)
	tooltip.show_tooltip()

func show_material_tooltip(pos : Vector2i, represented_material : GameManager.Materials):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_material_header(represented_material)
	tooltip.populate_rates(represented_material)
	tooltip.show_tooltip()

func show_rocket_tooltip(pos : Vector2i, materials : Array[GameManager.Materials], amounts : Array[int]):
	tooltip.position = pos
	tooltip.clear_icons()
	tooltip.add_rocket_header()
	tooltip.populate_costs(materials, amounts)
	tooltip.show_tooltip()

func hide_tooltip():
	tooltip.hide_tooltip()

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
				SoundManager.fade_to_track(fade_time, SoundManager.MusicTracks.EARLY)
				SoundManager.track_changing = true
			Screens.TITLE: 
				SoundManager.fade_to_track(fade_time, SoundManager.MusicTracks.MENU)
			Screens.END:
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
			GameManager.game_state = GameManager.GameState.GAME
			GameManager.timeskip_days = 0
		Screens.TITLE:
			GameManager.game_state = GameManager.GameState.MENU
	
	var new_screen = screen_scenes[current_screen_type].instantiate()
	add_child(new_screen)
	current_screen = new_screen
	
	if fade:
		await get_tree().create_timer(fade_time/3).timeout
		fade_in(fade_time/3)
		await fade_component.fade_in_finished
	empty_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if current_screen_type == Screens.END:
		current_screen.start_playing()

func fade_out(time : float):
	fade_component.fade_out(time)

func fade_in(time : float):
	fade_component.fade_in(time)

func print_to_code_window(text : String):
	code_text_added.emit(text)
