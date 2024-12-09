extends Control

@export
var hold_time : float = 2.0
@export
var fade_time : float = 2.0
@export
var hover_color : Color = Color.WHITE
@export
var fade_color : Color = Color.BLACK
@export
var active : bool = true : set = set_active

var fade_progress : float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().modulate = hover_color

func in_out_sine_ease(progress : float):
	return -(cos(PI*progress) - 1) / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !active:
		return
	
	if fade_progress > 0.0:
		var total_time = hold_time + fade_time
		fade_progress -= delta/total_time
		if fade_progress <= 0.0:
			fade_progress = 0.0
		
		var new_color : Color
		var hold_ratio = hold_time/total_time
		if fade_progress > hold_ratio:
			new_color = hover_color
		else:
			new_color = fade_color.lerp(hover_color, in_out_sine_ease(fade_progress/(1-hold_ratio)))
		
		get_parent().modulate = new_color

func _on_mouse_entered() -> void:
	trigger_hover()

func trigger_hover():
	if !active:
		return
	fade_progress = 1.0

func set_active(new_active : bool):
	active = new_active
	
	if !is_instance_valid(get_parent()):
		return
	
	if active:
		trigger_hover()
	else:
		get_parent().modulate = hover_color
