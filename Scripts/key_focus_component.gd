extends Node
class_name KeyFocusComponent

@export
var targeted_texture : String = "texture_focused"

var focus_texture : Texture

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_texture = get_parent().get(targeted_texture)
	UIManager.mouse_used.connect(_on_mouse_used)
	UIManager.ui_key_used.connect(_on_ui_key_used)
	
	get_parent().set(targeted_texture, null)

func _on_mouse_used():
	if get_parent().get(targeted_texture) == null:
		return
	get_parent().set(targeted_texture, null)
	if get_parent().has_focus():
		get_parent().release_focus()
		get_parent().grab_focus()

func _on_ui_key_used():
	if get_parent().get(targeted_texture) != null:
		return
	get_parent().set(targeted_texture, focus_texture)
	if get_parent().has_focus():
		get_parent().release_focus()
		get_parent().grab_focus()
