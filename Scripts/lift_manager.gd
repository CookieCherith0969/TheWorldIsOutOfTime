extends Node
class_name LiftManager

enum LiftState {IDLE, LIFTING, FALLING}
signal animation_complete
signal lift_complete
signal fall_complete
signal animation_started
signal lift_started
signal fall_started

@export
var targets : Array[Node]
@export
var lift_height : float = 100.0
@export
var lift_time : float = 2.0
var prev_lift_height : float = 0.0
var lift_progress : float = 0.0
var lift_state : LiftState = LiftState.IDLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func in_out_sine_ease(progress : float):
	return -(cos(PI*progress) - 1) / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if lift_state == LiftState.IDLE:
		return
	
	if lift_state == LiftState.LIFTING:
		lift_progress += delta/lift_time
		if lift_progress >= 1.0:
			lift_progress = 1.0
			lift_state = LiftState.IDLE
			animation_complete.emit()
			lift_complete.emit()
	else:
		lift_progress -= delta/lift_time
		if lift_progress <= 0.0:
			lift_progress = 0.0
			lift_state = LiftState.IDLE
			animation_complete.emit()
			fall_complete.emit()
	
	var new_lift_height : float = in_out_sine_ease(lift_progress)
	
	var height_diff = new_lift_height - prev_lift_height
	
	for target in targets:
		target.position.y -= height_diff*lift_height
	
	prev_lift_height = new_lift_height

func begin_lift():
	lift_progress = 0.0
	lift_state = LiftState.LIFTING
	animation_started.emit()
	lift_started.emit()

func begin_fall():
	lift_progress = 1.0
	lift_state = LiftState.FALLING
	animation_started.emit()
	fall_started.emit()
