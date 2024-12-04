extends RichTextLabel

@export_multiline
var text_template : String = "%02d[font_size=16] Years [/font_size]%02d[font_size=16] Months [/font_size]%02d[font_size=16] Days [/font_size]"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.day_ended.connect(on_day_ended)
	update_label()

func on_day_ended():
	update_label()

func update_label():
	var mixed_time : Array[int] = GameManager.get_mixed_time()
	
	text = text_template % mixed_time
