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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.texture = GameManager.get_material_icon(represented_material)
	update_labels()
	
	GameManager.materials_updated.connect(on_materials_updated)
	if hide_gain:
		gain_label.hide()

func on_materials_updated():
	update_labels()

func update_labels():
	amount_label.text = UIManager.simplify_number(GameManager.get_material_amount(represented_material))
	var prefix : String = ""
	var change : int = GameManager.get_prev_day_change(represented_material)
	if change > 0:
		prefix = "+"
	gain_label.text = prefix+UIManager.simplify_number(change)+"/d"

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
	
	UIManager.show_material_tooltip(tooltip_marker.global_position, represented_material)

func _on_mouse_exited() -> void:
	UIManager.hide_tooltip()

func _on_focus_entered() -> void:
	focus.show()
	if empty:
		return
	
	UIManager.show_material_tooltip(tooltip_marker.global_position, represented_material)

func _on_focus_exited() -> void:
	focus.hide()
	UIManager.hide_tooltip()
