extends Label
class_name DifficultyLabel

@export
var normal_text : String = "Normal"
@export
var medium_text : String = "Medium"
@export
var hard_text : String = "Hard"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.difficulty_changed.connect(_on_difficulty_changed)
	update_text()

func _on_difficulty_changed():
	update_text()

func update_text():
	match(GameManager.difficulty):
		GameManager.Difficulty.NORMAL:
			text = normal_text
		GameManager.Difficulty.MEDIUM:
			text = medium_text
		GameManager.Difficulty.HARD:
			text = hard_text
