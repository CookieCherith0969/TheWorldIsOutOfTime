extends TextureButton

@export
var rocket_materials : Array[GameManager.Materials]
@export
var rocket_amounts : Array[int]

@onready
var tooltip_marker : Marker2D = $TooltipMarker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.materials_updated.connect(on_materials_updated)
	GameManager.timeskip_started.connect(on_timeskip_started)
	GameManager.timeskip_ended.connect(on_timeskip_ended)

func on_materials_updated():
	update_button()

func on_timeskip_started(_num_days : int):
	update_button()
	
func on_timeskip_ended():
	update_button()

func update_button():
	if GameManager.is_timeskipping():
		disabled = true
		return
	if GameManager.game_over:
		disabled = true
		return
	
	if GameManager.has_material_amounts(rocket_materials, rocket_amounts):
		disabled = false
	else:
		disabled = true

func _on_mouse_entered() -> void:
	UIManager.show_build_tooltip(tooltip_marker.global_position, rocket_materials, rocket_amounts)

func _on_mouse_exited() -> void:
	UIManager.hide_tooltip()

func _on_focus_entered() -> void:
	UIManager.show_build_tooltip(tooltip_marker.global_position, rocket_materials, rocket_amounts)

func _on_focus_exited() -> void:
	UIManager.hide_tooltip()

func _on_pressed() -> void:
	GameManager.launch_rocket()
