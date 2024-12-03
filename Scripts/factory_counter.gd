extends Control

@export
var represented_factory : FactoryInfo
var factory_index : int
@onready
var icon_box : HBoxContainer = $IconBox
@onready
var icon_scene : PackedScene = preload("res://Scenes/factory_icon.tscn")
@onready
var num_box : HBoxContainer = $NumBox
@onready
var num_scene : PackedScene = preload("res://Scenes/factory_label.tscn")
@onready
var amount_label : Label = $AmountLabel
@onready
var build_progress_bar : ProgressBar = $BuildProgressBar
@onready
var building_wrench : TextureRect = $BuildingWrench
@onready
var arrow_texture : Texture = preload("res://Sprites/PlaceholderArrow.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	factory_index = GameManager.get_factory_index(represented_factory)
	GameManager.factory_amount_updated.connect(on_factory_amount_updated)
	GameManager.factory_build_progressed.connect(on_factory_build_progressed)
	GameManager.timeskip_started.connect(on_timeskip_started)
	GameManager.timeskip_ended.connect(on_timeskip_ended)
	
	populate_icons()
	populate_nums()
	update_amounts()
	update_progress(0)

func on_factory_amount_updated(updated_factory : FactoryInfo):
	if updated_factory == represented_factory:
		update_amounts()
		if GameManager.get_planned_factory_amount(factory_index) > 0:
			building_wrench.show()
		else:
			building_wrench.hide()

func on_factory_build_progressed(updated_factory : FactoryInfo, day_progress : int):
	if updated_factory == represented_factory:
		update_progress(day_progress)

func on_timeskip_started(_num_days : int):
	building_wrench.texture.pause = false
	
func on_timeskip_ended(_num_days : int):
	building_wrench.texture.pause = true

func populate_icons():
	# Remove any existing icons
	for icon in icon_box.get_children():
		icon_box.remove_child(icon)
		icon.queue_free()
	
	# Input Icons
	for input_mat in represented_factory.input_materials:
		var input_icon : TextureRect = icon_scene.instantiate()
		
		input_icon.texture = GameManager.material_icons[input_mat]
		icon_box.add_child(input_icon)
	
	# Arrow Icon
	var arrow_icon : TextureRect = icon_scene.instantiate()
		
	arrow_icon.texture = arrow_texture
	icon_box.add_child(arrow_icon)
	
	# Output Icons
	for output_mat in represented_factory.output_materials:
		var output_icon : TextureRect = icon_scene.instantiate()
		
		output_icon.texture = GameManager.material_icons[output_mat]
		icon_box.add_child(output_icon)
	
	#icon_box.size.x = 16 * icon_box.get_child_count() + 4 * (icon_box.get_child_count()-1)

func populate_nums():
	for num in num_box.get_children():
		num_box.remove_child(num)
		num.queue_free()
	
	# Input Nums
	for input_num in represented_factory.inputs_per_day:
		var input_label : Label = num_scene.instantiate()
		
		input_label.text = UIManager.simplify_number(input_num)
		num_box.add_child(input_label)
	
	# Arrow Spacer
	var spacer_label : Label = num_scene.instantiate()
	
	num_box.add_child(spacer_label)
	
	# Output Nums
	for output_num in represented_factory.outputs_per_day:
		var output_label : Label = num_scene.instantiate()
		
		output_label.text = UIManager.simplify_number(output_num)
		num_box.add_child(output_label)
	
	num_box.size.x = 16 * num_box.get_child_count() + 4 * (num_box.get_child_count()-1)
	num_box.set_anchors_preset(Control.PRESET_CENTER_TOP, true)

func update_amounts():
	amount_label.text = "%s/%s" % [GameManager.get_active_factory_amount(factory_index), GameManager.get_total_factory_amount(factory_index)]

func update_progress(day_progress : int):
	var progress_ratio : float = float(day_progress)/float(represented_factory.build_days)
	build_progress_bar.value = progress_ratio*100.0
