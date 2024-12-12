extends Label
class_name DifficultyLabel

@export
var normal_text : String = "Normal"
@export
var hard_text : String = "Hard"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.hard_mode_toggled.connect(_on_hard_mode_toggled)
	update_text()

func _on_hard_mode_toggled():
	update_text()

func update_text():
	if GameManager.hard_mode:
		text = hard_text
	else:
		text = normal_text
