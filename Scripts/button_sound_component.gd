extends Node
class_name ButtonSoundComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().button_down.connect(_on_button_down)
	get_parent().button_up.connect(_on_button_up)

func _on_button_down() -> void:
	SoundManager.play_button_down()

func _on_button_up() -> void:
	SoundManager.play_button_up()
