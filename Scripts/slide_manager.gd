extends Node
class_name SlideManager

enum SlideState {IDLE, FORWARD, BACKWARD}
signal slide_complete
signal forward_complete
signal backward_complete
signal slide_started
signal forward_started
signal backward_started

@export
var targets : Array[Node]
@export
var slide_target_pos : Vector2 = Vector2(0,0)
@export
var slide_time : float = 2.0
var prev_slide_pos : Vector2 = Vector2(0,0)
var slide_progress : float = 0.0
var slide_state : SlideState = SlideState.IDLE

func in_out_sine_ease(progress : float):
	return -(cos(PI*progress) - 1) / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if slide_state == SlideState.IDLE:
		return
	
	if slide_state == SlideState.FORWARD:
		slide_progress += delta/slide_time
		if slide_progress >= 1.0:
			slide_progress = 1.0
			slide_state = SlideState.IDLE
			slide_complete.emit()
			forward_complete.emit()
	else:
		slide_progress -= delta/slide_time
		if slide_progress <= 0.0:
			slide_progress = 0.0
			slide_state = SlideState.IDLE
			slide_complete.emit()
			backward_complete.emit()
	
	var new_slide_pos : Vector2 = Vector2(in_out_sine_ease(slide_progress), in_out_sine_ease(slide_progress))
	
	var pos_diff = new_slide_pos - prev_slide_pos
	
	for target in targets:
		target.position += pos_diff*slide_target_pos
	
	prev_slide_pos = new_slide_pos

func slide_forward():
	slide_progress = 0.0
	slide_state = SlideState.FORWARD
	slide_started.emit()
	forward_started.emit()

func slide_backward():
	slide_progress = 1.0
	slide_state = SlideState.BACKWARD
	slide_started.emit()
	backward_started.emit()
