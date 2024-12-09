extends MarginContainer
class_name TutorialPopup

signal popup_dismissed

@onready
var hor_line : Line2D = $HorizontalLine
@onready
var vert_line : Line2D = $VerticalLine
@onready
var popup_label : Label = $InnerMargin/PopupLabel


func set_text(text : String):
	popup_label.text = text
	size = Vector2(1,1)

func set_center_position(pos : Vector2i):
	global_position = pos - Vector2i(size/2)

func set_target(target_position : Vector2i):
	var popup_center : Vector2i = Vector2i(size/2)
	var global_popup_center : Vector2i = Vector2i(global_position) + Vector2i(size/2)
	hor_line.global_position = global_popup_center
	hor_line.points[1].y = 0
	hor_line.points[1].x = target_position.x - global_popup_center.x
	
	vert_line.global_position = global_popup_center + Vector2i(hor_line.points[1])
	vert_line.points[1].x = 0
	vert_line.points[1].y = target_position.y - global_popup_center.y


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index < 3 && event.pressed:
			popup_dismissed.emit()
	elif event.is_action_pressed("ui_accept"):
		popup_dismissed.emit()


func _on_focus_exited() -> void:
	if visible:
		grab_focus()


func _on_screen_cover_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index < 3 && event.pressed:
			popup_dismissed.emit()
	elif event.is_action_pressed("ui_accept"):
		popup_dismissed.emit()
