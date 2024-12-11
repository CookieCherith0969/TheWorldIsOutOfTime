extends Control
class_name FactoryCounter

signal factory_unlocked(factory : FactoryInfo, counter_index : int)

@export
var represented_factory : FactoryInfo : set = set_rep_factory
var factory_index : int

@onready
var icon_box : HBoxContainer = $IconBox
@export
var icon_scene : PackedScene
@export
var arrow_texture : Texture

@onready
var num_box : HBoxContainer = $NumBox
@onready
var num_scene : PackedScene = preload("res://Scenes/factory_label.tscn")

@onready
var amount_label : Label = $AmountLabel
@onready
var build_progress_bar : ProgressBar = $BuildProgressBar
@onready
var building_wrench : AnimatedSprite2D = $BuildingWrench

@onready
var unplan_button : TextureButton = $UnplanButton
@onready
var plan_button : TextureButton = $PlanButton

@onready
var tooltip_marker : Marker2D = $TooltipMarker

var unlocked : bool = false
@onready
var lock_panel : Panel = $LockPanel
@onready
var unlock_button : TextureButton = $LockPanel/UnlockButton

@onready
var background : NinePatchRect = $BackgroundRect
@export
var unlocked_background : Texture
@export
var locked_background : Texture

@onready
var sketch_sound : AudioStreamPlayer = $SketchSound
@onready
var erase_sound : AudioStreamPlayer = $EraseSound

var days_per_wrench_turn : int = 2
var wrench_days : int = 0

var empty : bool = false

var showing_tooltip : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	factory_index = GameManager.get_factory_index(represented_factory)
	GameManager.factory_amount_updated.connect(on_factory_amount_updated)
	GameManager.factory_build_progressed.connect(on_factory_build_progressed)
	GameManager.timeskip_started.connect(on_timeskip_started)
	GameManager.timeskip_ended.connect(on_timeskip_ended)
	GameManager.day_ended.connect(on_day_ended)
	
	set_rep_factory(represented_factory)

func _input(event: InputEvent) -> void:
	if !showing_tooltip:
		return
	if event.is_action_pressed("FactoryFifty") || event.is_action_pressed("FactoryTen"):
		show_tooltip()
	if event.is_action_released("FactoryFifty") || event.is_action_released("FactoryTen"):
		show_tooltip()

func on_day_ended():
	wrench_days += 1
	if wrench_days >= days_per_wrench_turn:
		wrench_days -= days_per_wrench_turn
		
		var new_frame : int = building_wrench.frame + 1
		new_frame %= building_wrench.sprite_frames.get_frame_count("default")
		building_wrench.frame = new_frame

func on_factory_amount_updated(updated_factory : FactoryInfo):
	if updated_factory == represented_factory:
		update_amounts()
		
	update_buttons()

func on_factory_build_progressed(updated_factory : FactoryInfo, day_progress : int):
	if updated_factory == represented_factory:
		update_progress(day_progress)

func on_timeskip_started(_num_days : int):
	update_buttons()
	
func on_timeskip_ended():
	update_buttons()

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
		
		if input_num != 0:
			input_label.text = UIManager.simplify_number(input_num)
		else:
			input_label.text = ""
		
		num_box.add_child(input_label)
	
	# Arrow Spacer
	var spacer_label : Label = num_scene.instantiate()
	
	num_box.add_child(spacer_label)
	num_box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Output Nums
	for output_num in represented_factory.outputs_per_day:
		var output_label : Label = num_scene.instantiate()
		
		if output_num != 0:
			output_label.text = UIManager.simplify_number(output_num)
		else:
			output_label.text = ""
		
		num_box.add_child(output_label)
	
	# Daily Indicator
	#if !represented_factory.output_on_build:
	#	var daily_label : Label = num_scene.instantiate()
	#	
	#	daily_label.text = "/d"
	#	num_box.add_child(daily_label)

func update_amounts():
	if represented_factory.keep_zero_factory_active_amount:
		amount_label.text = "%s" % GameManager.get_planned_factory_amount(factory_index)
	else:
		amount_label.text = "%s/%s" % [GameManager.get_active_factory_amount(factory_index), GameManager.get_total_factory_amount(factory_index)]
	if !empty:
			if GameManager.get_planned_factory_amount(factory_index) != 0:
				building_wrench.show()
			else:
				building_wrench.hide()
	update_buttons()

func update_progress(day_progress : int):
	if day_progress < 0:
		build_progress_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	else:
		build_progress_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
	
	var progress_ratio : float = abs(day_progress)/float(represented_factory.build_days)
	build_progress_bar.value = progress_ratio*100.0

func update_buttons():
	if GameManager.is_timeskipping():
		unplan_button.disabled = true
		plan_button.disabled = true
		unlock_button.disabled = true
		return
	if GameManager.game_state != GameManager.GameState.GAME:
		unplan_button.disabled = true
		plan_button.disabled = true
		unlock_button.disabled = true
		return
	
	if GameManager.get_total_factory_amount(factory_index) <= 0:
		unplan_button.disabled = true
	else:
		unplan_button.disabled = false
	
	if GameManager.get_planned_factory_amount(factory_index) < 0 || GameManager.can_build_factory(factory_index):
		plan_button.disabled = false
	else:
		plan_button.disabled = true
	
	if GameManager.can_unlock_factory(factory_index):
		unlock_button.disabled = false
	else:
		unlock_button.disabled = true

func _on_plan_button_pressed() -> void:
	var multiplier : int = 1
	if Input.is_action_pressed("FactoryTen"):
		multiplier *= 10
	if Input.is_action_pressed("FactoryFifty"):
		multiplier *= 50
	for i in range(multiplier):
		if !GameManager.plan_factory(factory_index):
			break
	sketch_sound.play()
	show_tooltip()

func _on_unplan_button_pressed() -> void:
	var multiplier : int = 1
	if Input.is_action_pressed("FactoryTen"):
		multiplier *= 10
	if Input.is_action_pressed("FactoryFifty"):
		multiplier *= 50
	for i in range(multiplier):
		if !GameManager.unplan_factory(factory_index):
			break
	
	erase_sound.play()
	show_tooltip()

func _on_mouse_entered() -> void:
	show_tooltip()

func _on_mouse_exited() -> void:
	showing_tooltip = false
	UIManager.hide_tooltip()

func _on_focus_entered() -> void:
	show_tooltip()

func _on_focus_exited() -> void:
	showing_tooltip = false
	UIManager.hide_tooltip()

func show_tooltip():
	showing_tooltip = true
	if empty:
		return
	
	if unlocked:
		var build_materials : Array[GameManager.Materials]
		build_materials.assign(represented_factory.build_materials)
		var amount_mult : int = 1
		if Input.is_action_pressed("FactoryTen"):
			amount_mult *= 10
		if Input.is_action_pressed("FactoryFifty"):
			amount_mult *= 50
		var build_amounts : Array[int]
		build_amounts.assign(represented_factory.build_amounts)
		for i in build_amounts.size():
			build_amounts[i] *= amount_mult
		UIManager.show_build_tooltip(tooltip_marker.global_position, build_materials, build_amounts, represented_factory.build_days*amount_mult)
	else:
		var research_materials : Array[GameManager.Materials]
		research_materials.assign(represented_factory.research_materials)
		UIManager.show_unlock_tooltip(tooltip_marker.global_position, research_materials, represented_factory.research_amounts)


func get_right_button() -> TextureButton:
	if unlocked:
		return plan_button
	else:
		return unlock_button

func get_left_button() -> TextureButton:
	if unlocked:
		return unplan_button
	else:
		return unlock_button

func unlock():
	lock_panel.hide()
	
	if !represented_factory.hide_material_amounts:
		num_box.show()
	amount_label.show()
	unplan_button.show()
	plan_button.show()
	
	background.texture = unlocked_background
	unlocked = true
	#GameManager.unlock_factory(factory_index)

func lock():
	lock_panel.show()
	
	#num_box.hide()
	amount_label.hide()
	unplan_button.hide()
	plan_button.hide()
	
	background.texture = locked_background
	unlocked = false

func _on_unlock_button_pressed() -> void:
	if GameManager.can_unlock_factory(factory_index):
		GameManager.unlock_factory(factory_index)
		unlock()
		factory_unlocked.emit(represented_factory, get_index())
		UIManager.hide_tooltip()

func set_rep_factory(new_factory):
	represented_factory = new_factory
	empty = false
	factory_index = GameManager.get_factory_index(represented_factory)
	if !is_instance_valid(icon_box):
		return
	
	icon_box.show()
	num_box.show()
	amount_label.show()
	build_progress_bar.show()
	unplan_button.show()
	plan_button.show()
	
	unlocked = GameManager.is_factory_unlocked(factory_index)
	
	populate_icons()
	populate_nums()
	update_amounts()
	update_progress(GameManager.factory_build_progress[factory_index])
	
	if unlocked:
		unlock()
	else:
		lock()
	
	

func set_empty():
	empty = true
	icon_box.hide()
	num_box.hide()
	amount_label.hide()
	build_progress_bar.hide()
	unplan_button.hide()
	plan_button.hide()
	lock_panel.hide()
	background.texture = locked_background
	building_wrench.hide()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		if !unlocked:
			return
		if GameManager.is_timeskipping():
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			GameManager.plan_factory(factory_index)
			show_tooltip()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			GameManager.unplan_factory(factory_index)
			show_tooltip()
			get_viewport().set_input_as_handled()
