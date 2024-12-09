extends MarginContainer
class_name TimeCounter

@export_multiline
var text_template : String = "%0d[font_size=8] Years [/font_size]%d[font_size=8] Months [/font_size]%d[font_size=8] Days [/font_size]"

@onready
var time_label : RichTextLabel = $InnerMargin/TimeLabel

@export
var tooltip_marker : Marker2D
@export
var focus : NinePatchRect

var tooltip_visible : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.day_ended.connect(on_day_ended)
	update_label()

func on_day_ended():
	update_label()
	if tooltip_visible:
		UIManager.show_time_tooltip(tooltip_marker.global_position)

func update_label():
	var mixed_time : Array[int] = GameManager.get_mixed_time()
	
	time_label.text = text_template % mixed_time


func _on_mouse_entered() -> void:
	tooltip_visible = true
	UIManager.show_time_tooltip(tooltip_marker.global_position)

func _on_mouse_exited() -> void:
	tooltip_visible = false
	UIManager.hide_tooltip()

func _on_focus_entered() -> void:
	focus.show()
	tooltip_visible = true
	UIManager.show_time_tooltip(tooltip_marker.global_position)

func _on_focus_exited() -> void:
	focus.hide()
	tooltip_visible = false
	UIManager.hide_tooltip()
