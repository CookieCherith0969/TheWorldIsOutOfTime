extends CanvasLayer

@export
var tooltip : Tooltip
const tooltip_hold_time : float = 1
const tooltip_fade_time : float = 1

const simplification_suffixes = [
	"",
	"K",
	"M",
	"B",
	"T",
	"Q"
]
const round_up_leniency = 0.025

var current_game_screen : Control
@export
var game_screen_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().min_size = get_viewport().size
	make_new_game_screen()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DebugReset"):
		make_new_game_screen()

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

func show_build_tooltip(pos : Vector2i, factory : FactoryInfo):
	tooltip.set_position(pos)
	tooltip.populate_build_costs(factory)
	tooltip.show_tooltip()
	
func show_unlock_tooltip(pos : Vector2i, factory : FactoryInfo):
	tooltip.set_position(pos)
	tooltip.populate_unlock_costs(factory)
	tooltip.show_tooltip()
	
func hide_tooltip():
	tooltip.hide_tooltip()

func fade_tooltip():
	tooltip.begin_fade(tooltip_hold_time, tooltip_fade_time)



func make_new_game_screen():
	if is_instance_valid(current_game_screen):
		remove_child(current_game_screen)
		current_game_screen.queue_free()
	var new_game_screen = game_screen_scene.instantiate()
	add_child(new_game_screen)
	current_game_screen = new_game_screen
