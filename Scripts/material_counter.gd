extends Control
class_name MaterialCounter

@export
var represented_material : GameManager.Materials = GameManager.Materials.STONE : set = set_rep_material
@export
var hide_gain : bool = false
@export
var empty : bool = false

@onready
var icon : TextureRect = $Icon
@onready
var amount_label : Label = $AmountLabel
@onready
var gain_label : Label = $GainLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.texture = GameManager.get_material_icon(represented_material)
	update_labels()
	
	GameManager.day_ended.connect(on_day_ended)
	GameManager.factory_amount_updated.connect(on_factory_amount_updated)
	if hide_gain:
		gain_label.hide()

func on_day_ended():
	update_labels()

func on_factory_amount_updated(_factory : FactoryInfo):
	update_labels()

func update_labels():
	amount_label.text = UIManager.simplify_number(GameManager.get_material_amount(represented_material))
	gain_label.text = UIManager.simplify_number(GameManager.get_prev_day_material_gain(represented_material))+" /d"

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
