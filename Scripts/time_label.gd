extends MarginContainer
class_name TimeCounter

@export_multiline
var text_template : String = "%0d[font_size=8] Years [/font_size]%d[font_size=8] Months [/font_size]%d[font_size=8] Days [/font_size]"

@onready
var time_label : RichTextLabel = $InnerMargin/TimeLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.day_ended.connect(on_day_ended)
	update_label()

func on_day_ended():
	update_label()

func update_label():
	var mixed_time : Array[int] = GameManager.get_mixed_time()
	
	time_label.text = text_template % mixed_time
