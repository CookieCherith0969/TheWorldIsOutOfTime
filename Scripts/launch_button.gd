extends TextureButton
class_name LaunchButton

@export
var rocket_materials : Array[GameManager.Materials]
@export
var rocket_amounts : Array[int]

@onready
var tooltip_marker : Marker2D = $TooltipMarker

var showing_tooltip : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.materials_updated.connect(on_materials_updated)
	GameManager.timeskip_started.connect(on_timeskip_started)
	GameManager.timeskip_ended.connect(on_timeskip_ended)
	UIManager.tooltip_shown.connect(_on_tooltip_shown)

func on_materials_updated():
	update_button()
	if showing_tooltip:
		show_tooltip()

func on_timeskip_started(_num_days : int):
	update_button()
	
func on_timeskip_ended():
	update_button()

func _on_tooltip_shown():
	showing_tooltip = false

func update_button():
	if GameManager.is_timeskipping():
		disabled = true
		return
	if GameManager.game_state != GameManager.GameState.GAME:
		disabled = true
		return
	
	if GameManager.has_material_amounts(rocket_materials, rocket_amounts):
		disabled = false
	else:
		disabled = true

func show_tooltip():
	UIManager.show_rocket_tooltip(tooltip_marker.global_position, rocket_materials, rocket_amounts)
	showing_tooltip = true

func _on_mouse_entered() -> void:
	show_tooltip()

func _on_mouse_exited() -> void:
	UIManager.hide_tooltip()
	showing_tooltip = false

func _on_focus_entered() -> void:
	show_tooltip()

func _on_focus_exited() -> void:
	UIManager.hide_tooltip()
	showing_tooltip = false

func _on_pressed() -> void:
	GameManager.launch_rocket()
