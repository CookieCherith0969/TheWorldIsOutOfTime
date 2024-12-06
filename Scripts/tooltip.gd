extends MarginContainer
class_name Tooltip

@onready
var inner_margin : MarginContainer = $InnerMargin
@onready
var icon_list : VBoxContainer = $InnerMargin/IconList

@export
var cost_icon_scene : PackedScene
@export
var header_icon_scene : PackedScene

@export
var time_icon : Texture
@export
var build_icon : Texture
@export
var lock_icon : Texture

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
	
	size.y = 1

func add_build_header():
	add_header_icon(build_icon)
	
func add_unlock_header():
	add_header_icon(lock_icon)

func add_time_cost(amount : int):
	add_time_cost_icon(amount)

func add_header_icon(texture : Texture):
	var header_icon : TextureRect = header_icon_scene.instantiate()
	header_icon.texture = texture
	icon_list.add_child(header_icon)

# Type checking for Arrays of Enums doesn't seem to work properly, so materials is a generic array instead
func add_icons_from_material_amounts(materials : Array[GameManager.Materials], amounts : Array[int]):
	for i in range(materials.size()):
		var new_icon : TooltipCostIcon = cost_icon_scene.instantiate()
		var icon_material = materials[i]
		var icon_amount = amounts[i]
		
		icon_list.add_child(new_icon)
		new_icon.set_cost_material(icon_material)
		new_icon.set_cost_amount(icon_amount)

func add_time_cost_icon(length : int):
	var time_cost : TooltipCostIcon = cost_icon_scene.instantiate()
	
	icon_list.add_child(time_cost)
	time_cost.set_custom_icon(time_icon)
	time_cost.set_cost_amount(length)

func clear_icons():
	for child in icon_list.get_children():
		icon_list.remove_child(child)
		child.queue_free()

func show_tooltip():
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
