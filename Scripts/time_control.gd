extends MarginContainer
class_name TimeControl

var selected_exponent : int = 0
var max_exponent : int = 12
var max_hard_exponent : int = 8

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
	update_label()

func on_timeskip_ended():
	update_buttons()
	update_label()

func on_day_ended():
	update_buttons()
	update_label()

func _on_halve_button_pressed() -> void:
	halve_time()

func _on_double_button_pressed() -> void:
	double_time()

func halve_time():
	if GameManager.is_timeskipping():
		return
	selected_exponent -= 1
	if selected_exponent < 0:
		selected_exponent = 0
	update_buttons()
	update_label()
	if GameManager.hard_mode:
		GameManager.hard_mode_speed = pow(2, selected_exponent)
	UIManager.print_to_code_window("halve_time()")

func double_time():
	if GameManager.is_timeskipping():
		return
	selected_exponent += 1
	if GameManager.hard_mode:
		if selected_exponent > max_hard_exponent:
			selected_exponent = max_hard_exponent
	else:
		if selected_exponent > max_exponent:
			selected_exponent = max_exponent
	
	update_buttons()
	update_label()
	if GameManager.hard_mode:
		GameManager.hard_mode_speed = pow(2, selected_exponent)
	UIManager.print_to_code_window("double_time()")

func _on_timeskip_button_pressed() -> void:
	var number_of_days : int = pow(2, selected_exponent)
	GameManager.process_days(number_of_days)
	#GameManager.process_until_all_built()
	UIManager.print_to_code_window("process_days(%s)"%number_of_days)
	selected_exponent = 0

func update_buttons():
	if GameManager.is_timeskipping():
		halve_button.disabled = true
		double_button.disabled = true
		timeskip_button.disabled = true
		return
	if GameManager.game_state != GameManager.GameState.GAME:
		halve_button.disabled = true
		double_button.disabled = true
		timeskip_button.disabled = true
		return
	if GameManager.hard_mode:
		timeskip_button.disabled = true
	else:
		timeskip_button.disabled = false
		
	
	if selected_exponent <= 0:
		halve_button.disabled = true
	else:
		halve_button.disabled = false
	
	if selected_exponent >= max_exponent:
		double_button.disabled = true
	else:
		double_button.disabled = false

func update_label():
	if GameManager.is_timeskipping():
		duration_label.text = str(GameManager.timeskip_days)
		return
	
	var duration = pow(2, selected_exponent)
	duration_label.text = str(duration)
	if duration >= GameManager.days_left:
		duration_label.add_theme_color_override("font_color", UIManager.palette_red)
	else:
		duration_label.add_theme_color_override("font_color", UIManager.palette_black)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			double_time()
			update_buttons()
			update_label()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			halve_time()
			update_buttons()
			update_label()
