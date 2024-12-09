extends Node
class_name BobbingComponent

@export
var bobbing_speed : float = 1.0
@export
var bobbing_height : float = 8.0
@export
var bob_offset : float = 0.0

var bob_progress : float = 0.0
var prev_bob_height : float = 0.0

func _ready():
	bob_progress += bob_offset

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	bob_progress += delta*bobbing_speed
	if bob_progress > 2*PI:
		bob_progress -= 2*PI
	
	var new_bob_height : float = sin(bob_progress)
	
	var height_diff = new_bob_height - prev_bob_height
	
	get_parent().position.y += height_diff*bobbing_height
	
	prev_bob_height = new_bob_height
