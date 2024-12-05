extends Control
class_name RocketCounter

@onready
var progress_label : Label = $InnerMargin/HBoxContainer/ProgressLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.day_ended.connect(on_day_ended)
	update_label()

func on_day_ended():
	update_label()

func update_label():
	var current_parts = GameManager.get_material_amount(GameManager.rocket_material)
	var needed_parts = GameManager.parts_per_rocket
	progress_label.text = str(current_parts*100 / needed_parts)
