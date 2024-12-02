extends CanvasLayer

@onready
var time_label : Label = $TextureRect/TimeLabel

const simplification_suffixes = [
	"",
	"K",
	"M",
	"B",
	"T"
]
const round_up_leniency = 0.025

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().min_size = get_viewport().size
	
	update_time_label()
	
	GameManager.day_ended.connect(on_day_ended)

func on_day_ended():
	update_time_label()

func update_time_label():
	var mixed_time : Array[int] = GameManager.get_mixed_time()
	
	time_label.text = "%s Years, %s Months, %s Days" % mixed_time

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DebugProgress"):
		GameManager.process_days(10)

func simplify_number(num : int, show_positive : bool = false) -> String:
	var plus_string = ""
	if num >= 0 && show_positive:
		plus_string = "+"
	
	if num == 0:
		return plus_string + "0"
	
	var magnitude : int = log(abs(num)) / log(10) + round_up_leniency
	var suffix_index = min(magnitude/3, simplification_suffixes.size()-1)
	
	var simplified_num : float = num/float(pow(1000,suffix_index))
	var truncated_num : float = snapped(simplified_num, 0.1)
	var num_string = ""
	if suffix_index <= 0:
		num_string = str(truncated_num)
	else:
		num_string = "%.01f" % truncated_num
	
	return plus_string + num_string + simplification_suffixes[suffix_index]
