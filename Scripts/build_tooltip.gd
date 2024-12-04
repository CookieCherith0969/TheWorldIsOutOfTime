extends MarginContainer
class_name BuildTooltip

@onready
var icon_list : VBoxContainer = $ListMargin/IconList
@export
var cost_icon_scene : PackedScene

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

func populate_costs_from_factory(factory : FactoryInfo):
	clear_costs()
	
	for i in range(factory.build_materials.size()):
		var new_cost : BuildCostIcon = cost_icon_scene.instantiate()
		var build_material = factory.build_materials[i]
		var amount = factory.build_amounts[i]
		
		icon_list.add_child(new_cost)
		new_cost.set_build_material(build_material)
		new_cost.set_build_amount(amount)
	
	var time_cost : BuildCostIcon = cost_icon_scene.instantiate()
	var time_amount = factory.build_days
	
	icon_list.add_child(time_cost)
	time_cost.set_time_icon()
	time_cost.set_build_amount(time_amount)
	
	size.y = 1

func clear_costs():
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
