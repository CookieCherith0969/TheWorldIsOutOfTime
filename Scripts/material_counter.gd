extends Control

@export
var represented_material : GameManager.Materials = GameManager.Materials.STONE : set = set_rep_material

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

func on_day_ended():
	update_labels()

func on_factory_amount_updated(factory : FactoryInfo):
	update_labels()

func update_labels():
	amount_label.text = UIManager.simplify_number(GameManager.get_material_amount(represented_material))
	gain_label.text = UIManager.simplify_number(GameManager.get_prev_day_material_gain(represented_material))+" /d"

func set_rep_material(new_material):
	represented_material = new_material
	if !is_instance_valid(icon):
		return
	icon.texture = GameManager.get_material_icon(represented_material)
