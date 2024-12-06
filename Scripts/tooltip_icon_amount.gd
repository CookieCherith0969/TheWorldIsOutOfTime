extends HBoxContainer
class_name TooltipIconAmount

@onready
var icon_rect : TextureRect = $IconRect
@onready
var amount_label : Label = $AmountLabel

func set_icon(icon : Texture):
	icon_rect.texture = icon

func set_amount(amount : int):
	amount_label.text = UIManager.simplify_number(amount)

func set_amount_formatted(amount : int, format_string : String):
	amount_label.text = format_string % UIManager.simplify_number(amount)
