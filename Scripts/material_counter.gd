extends Control
class_name MaterialCounter

@export
var represented_material : GameManager.Materials = GameManager.Materials.STONE : set = set_rep_material
@export
var hide_gain : bool = false
@export
var empty : bool = false

@onready
var icon : TextureRect = $InnerMargin/Icon
@onready
var amount_label : Label = $InnerMargin/AmountLabel
@onready
var gain_label : Label = $InnerMargin/GainLabel

@onready
var tooltip_marker : Marker2D = $TooltipMarker
@onready
var focus : NinePatchRect = $OuterMargin/Focus

var showing_tooltip : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.texture = GameManager.get_material_icon(represented_material)
	update_labels()
	
	GameManager.materials_updated.connect(on_materials_updated)
	UIManager.tooltip_shown.connect(_on_tooltip_shown)
	if hide_gain:
		gain_label.hide()

func on_materials_updated():
	update_labels()
	if showing_tooltip:
		show_tooltip()

func _on_tooltip_shown():
	showing_tooltip = false

func update_labels():
	amount_label.text = UIManager.simplify_number(GameManager.get_material_amount(represented_material))
	GameManager.get_predicted_change(represented_material)
	var prefix : String = ""
	var change : int = GameManager.get_prev_day_change(represented_material)
	var prediction : int = GameManager.get_predicted_change(represented_material)
	if prediction < 0:
		gain_label.add_theme_color_override("font_color", UIManager.palette_red)
	elif prediction != change:
		gain_label.add_theme_color_override("font_color", UIManager.palette_dark_blue)
	else:
		gain_label.add_theme_color_override("font_color", UIManager.palette_black)
	if prediction > 0:
		prefix = "+"
	gain_label.text = prefix+UIManager.simplify_number(prediction)+"/d"

func set_rep_material(new_material):
	represented_material = new_material
	empty = false
	if !is_instance_valid(icon):
		return
	
	icon.texture = GameManager.get_material_icon(represented_material)
	icon.show()
	amount_label.show()
	gain_label.show()
	
	update_labels()

func set_empty():
	empty = true
	icon.hide()
	amount_label.hide()
	gain_label.hide()

func _on_mouse_entered() -> void:
	if empty:
		return
	show_tooltip()

func _on_mouse_exited() -> void:
	UIManager.hide_tooltip()
	showing_tooltip = false

func _on_focus_entered() -> void:
	focus.show()
	if empty:
		return
	show_tooltip()

func _on_focus_exited() -> void:
	focus.hide()
	UIManager.hide_tooltip()
	showing_tooltip = false

func show_tooltip():
	UIManager.show_material_tooltip(tooltip_marker.global_position, represented_material)
	showing_tooltip = true
