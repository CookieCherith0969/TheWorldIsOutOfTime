extends MarginContainer
class_name Tooltip

@onready
var inner_margin : MarginContainer = $InnerMargin
@onready
var icon_list : VBoxContainer = $InnerMargin/IconList

@export
var icon_amount_scene : PackedScene
@export
var header_icon_scene : PackedScene

@export
var time_icon : Texture
@export
var build_icon : Texture
@export
var lock_icon : Texture
@export
var rocket_icon : Texture

@export
var increase_icon : Texture
@export
var decrease_icon : Texture
@export
var change_icon : Texture

var hold_time : float = 0.0
var fade_time : float = 0.0

var total_show_time : float = 0.0
var show_time : float = 0.0
var fading : bool = false

func _process(delta: float) -> void:
	if !visible:
		return
	if !fading:
		return
	
	show_time -= delta
	if show_time <= 0.0:
		hide()
		fading = false
		return
	
	var elapsed_time = total_show_time - show_time
	if elapsed_time <= hold_time:
		return
	
	var fade_progress = (elapsed_time - hold_time)/fade_time
	modulate = Color(1,1,1,1-fade_progress)

func populate_costs(materials : Array[GameManager.Materials], amounts : Array[int]):
	add_icons_from_material_amounts(materials, amounts)

func populate_rates(rate_material : GameManager.Materials):
	var increase_format : String = "%s/d"
	var decrease_format : String = "%s/d"
	var change_format : String = "%s/d"
	
	var increase : int = GameManager.get_prev_day_increase(rate_material)
	var decrease : int = GameManager.get_prev_day_decrease(rate_material)
	var change : int = GameManager.get_prev_day_change(rate_material)
	
	if increase > 0:
		increase_format = "+%s/d"
	if decrease > 0:
		decrease_format = "+%s/d"
	if change > 0:
		change_format = "+%s/d"
	
	add_icon_amount(increase_icon, increase, increase_format)
	add_icon_amount(decrease_icon, decrease, decrease_format)
	add_icon_amount(change_icon, change, change_format)

func add_build_header():
	add_header_icon(build_icon)
	
func add_unlock_header():
	add_header_icon(lock_icon)

func add_material_header(header_material : GameManager.Materials):
	add_header_icon(GameManager.get_material_icon(header_material), GameManager.get_material_name(header_material))

func add_rocket_header():
	add_header_icon(rocket_icon, "Rocket")

func add_time_cost(amount : int):
	add_icon_amount(time_icon, amount)

func add_header_icon(texture : Texture, text : String = ""):
	var header_icon : TooltipHeaderIcon = header_icon_scene.instantiate()
	icon_list.add_child(header_icon)
	header_icon.set_icon(texture)
	header_icon.set_label(text)

# Type checking for Arrays of Enums doesn't seem to work properly, so materials is a generic array instead
func add_icons_from_material_amounts(materials : Array[GameManager.Materials], amounts : Array[int]):
	for i in range(materials.size()):
		var material_icon = GameManager.get_material_icon(materials[i])
		var material_amount = amounts[i]
		add_icon_amount(material_icon, material_amount)

func add_icon_amount(icon : Texture, amount : int, format_string : String = ""):
	var new_icon : TooltipIconAmount = icon_amount_scene.instantiate()
	
	icon_list.add_child(new_icon)
	new_icon.set_icon(icon)
	
	if format_string.is_empty():
		new_icon.set_amount(amount)
	else:
		new_icon.set_amount_formatted(amount, format_string)

func clear_icons():
	for child in icon_list.get_children():
		icon_list.remove_child(child)
		child.queue_free()
	
	# Shrinks tooltip so that it doesn't overhang, in the cast that fewer icons are added than were previously present
	# Expanding is handled automatically by MarginContainer behaviour
	size.y = 1
	size.x = 1
	inner_margin.size.y = 1
	inner_margin.size.x = 1

func show_tooltip():
	size.x = inner_margin.size.x + inner_margin.get_theme_constant("margin_left") + inner_margin.get_theme_constant("margin_right")
	size.y = inner_margin.size.y + inner_margin.get_theme_constant("margin_top") + inner_margin.get_theme_constant("margin_bottom")
	show()
	fading = false
	modulate = Color(1,1,1,1)

func hide_tooltip():
	hide()
	fading = false

func begin_fade(temp_hold_time : float, temp_fade_time : float):
	hold_time = temp_hold_time
	fade_time = temp_fade_time
	total_show_time = hold_time + fade_time
	show_time = total_show_time
	fading = true
