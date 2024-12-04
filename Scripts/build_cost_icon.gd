extends HBoxContainer
class_name BuildCostIcon

@onready
var material_icon : TextureRect = $MaterialIcon
@onready
var amount_label : Label = $AmountLabel
@export
var time_icon : Texture

func set_build_material(material : GameManager.Materials):
	material_icon.texture = GameManager.material_icons[material]

func set_time_icon():
	material_icon.texture = time_icon

func set_build_amount(amount : int):
	amount_label.text = UIManager.simplify_number(amount)
