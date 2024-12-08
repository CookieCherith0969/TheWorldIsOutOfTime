extends Node
class_name FadeComponent

signal fade_started
signal fade_in_finished
signal fade_out_finished
signal fade_finished

enum FadeState {IDLE, FADING_IN, FADING_OUT}

var fade_progress : float = 1.0
var fade_time : float = 0.0
var fade_state : FadeState = FadeState.IDLE
@export
var in_color : Color = Color.WHITE
@export
var out_color : Color = Color.TRANSPARENT
@export
var target_self_modulate : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if fade_state == FadeState.IDLE:
		return
	
	if fade_state == FadeState.FADING_IN:
		fade_progress += delta / fade_time
		if fade_progress >= 1.0:
			fade_progress = 1.0
			fade_state = FadeState.IDLE
			fade_in_finished.emit()
			fade_finished.emit()
	
	elif fade_state == FadeState.FADING_OUT:
		fade_progress -= delta / fade_time
		if fade_progress <= 0.0:
			fade_progress = 0.0
			fade_state = FadeState.IDLE
			fade_out_finished.emit()
			fade_finished.emit()
	
	if target_self_modulate:
		get_parent().self_modulate = out_color.lerp(in_color, in_out_sine_ease(fade_progress))
	else:
		get_parent().modulate = out_color.lerp(in_color, in_out_sine_ease(fade_progress))

func in_out_sine_ease(progress : float):
	return -(cos(PI*progress) - 1) / 2

func fade_out(time : float):
	fade_progress = 1.0
	fade_time = time
	fade_state = FadeState.FADING_OUT
	fade_started.emit()

func fade_in(time : float):
	fade_progress = 0.0
	fade_time = time
	fade_state = FadeState.FADING_IN
	fade_started.emit()

func force_in_color():
	if target_self_modulate:
		get_parent().self_modulate = in_color
	else:
		get_parent().modulate = in_color

func force_out_color():
	if target_self_modulate:
		get_parent().self_modulate = out_color
	else:
		get_parent().modulate = out_color
