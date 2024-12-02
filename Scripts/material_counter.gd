extends HFlowContainer

@export
var represented_material : GameManager.Materials = GameManager.Materials.STONE

@onready
var icon : TextureRect = $Icon
@onready
var amount_label : Label = $AmountLabel
@onready
var gain_label : Label = $GainLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.texture = GameManager.get_material_icon(represented_material)
	amount_label.text = str(GameManager.get_material_amount(represented_material))
	gain_label.text = "+%s /d" % GameManager.get_prev_day_material_gain(represented_material)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	amount_label.text = str(GameManager.get_material_amount(represented_material))
	gain_label.text = "+%s /d" % GameManager.get_prev_day_material_gain(represented_material)
