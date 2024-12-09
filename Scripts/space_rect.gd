extends TextureRect
class_name SpaceRect

@export
var do_flipping : bool = true
@export
var do_rotating : bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if do_flipping:
		flip_h = randi() % 2 == 0
		flip_v = randi() & 2 == 0
	
	if do_rotating:
		pivot_offset = size/2
		rotation = randi_range(0,3)*PI/2
