extends HBoxContainer
class_name TooltipCostIcon

@onready
var material_icon : TextureRect = $MaterialIcon
@onready
var amount_label : Label = $AmountLabel

func set_cost_material(cost_material : GameManager.Materials):
	material_icon.texture = GameManager.material_icons[cost_material]

func set_custom_icon(icon : Texture):
	material_icon.texture = icon

func set_cost_amount(amount : int):
	amount_label.text = UIManager.simplify_number(amount)
