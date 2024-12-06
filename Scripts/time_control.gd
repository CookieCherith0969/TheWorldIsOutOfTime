extends MarginContainer
class_name TimeControl

var selected_exponent : int = 0
var max_exponent : int = 11

var normal_color : Color = Color.WHITE
var max_color : Color = Color.RED

@onready
var duration_label : Label = $InnerMargin/InnerBox/DurationLabel

@onready
var halve_button : TextureButton = $InnerMargin/InnerBox/HalveButton
@onready
var double_button : TextureButton = $InnerMargin/InnerBox/DoubleButton
@onready
var timeskip_button : TextureButton = $InnerMargin/InnerBox/TimeskipButton

func _ready() -> void:
	GameManager.timeskip_started.connect(on_timeskip_started)
	GameManager.timeskip_ended.connect(on_timeskip_ended)
	GameManager.day_ended.connect(on_day_ended)
	update_label()
	update_buttons()

func on_timeskip_started(_num_days):
	update_buttons()

func on_timeskip_ended():
	update_buttons()
	update_label()

func on_day_ended():
	update_label()

func _on_halve_button_pressed() -> void:
	selected_exponent -= 1
	if selected_exponent < 0:
		selected_exponent = 0
	update_buttons()
	update_label()

func _on_double_button_pressed() -> void:
	selected_exponent += 1
	if selected_exponent > max_exponent:
		selected_exponent = max_exponent
	update_buttons()
	update_label()

func _on_timeskip_button_pressed() -> void:
	GameManager.process_days(pow(2, selected_exponent))
	selected_exponent = 0

func update_buttons():
	if GameManager.is_timeskipping():
		halve_button.disabled = true
		double_button.disabled = true
		timeskip_button.disabled = true
		return
	
	if selected_exponent <= 0:
		halve_button.disabled = true
	else:
		halve_button.disabled = false
	
	if selected_exponent >= max_exponent:
		double_button.disabled = true
	else:
		double_button.disabled = false
	
	timeskip_button.disabled = false

func update_label():
	if GameManager.is_timeskipping():
		duration_label.text = str(GameManager.timeskip_days)
		return
	
	var duration = pow(2, selected_exponent)
	duration_label.text = str(duration)
	if duration >= GameManager.days_left:
		duration_label.add_theme_color_override("font_color", max_color)
	else:
		duration_label.add_theme_color_override("font_color", normal_color)
