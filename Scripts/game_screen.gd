extends TextureRect

var large_map_open : bool = false

@export
var small_map : Control
@export
var time_control : TimeControl
@export
var large_map : LargeMap
@export
var material_window : MarginContainer
@export
var factory_window : MarginContainer
@export
var factory_grid : GridContainer
var top_right_factory : FactoryCounter
@export
var minimise_button : TextureButton

func _ready() -> void:
	small_map.grab_focus()
	
	top_right_factory = factory_grid.get_child(factory_grid.columns-1)
	
	for factory in factory_grid.get_children():
		factory.factory_unlocked.connect(on_factory_unlocked)
	
	setup_focus_neighbours()
	update_focus_neighbours()

func setup_focus_neighbours():
	small_map.focus_neighbor_left = time_control.timeskip_button.get_path()
	minimise_button.focus_neighbor_left = time_control.timeskip_button.get_path()

func update_focus_neighbours():
	if large_map_open:
		time_control.timeskip_button.focus_neighbor_right = minimise_button.get_path()
		time_control.timeskip_button.focus_neighbor_bottom = minimise_button.get_path()
		time_control.halve_button.focus_neighbor_bottom = minimise_button.get_path()
		time_control.double_button.focus_neighbor_bottom = minimise_button.get_path()
	else:
		time_control.timeskip_button.focus_neighbor_right = small_map.get_path()
		time_control.timeskip_button.focus_neighbor_bottom = top_right_factory.get_right_button().get_path()
		time_control.halve_button.focus_neighbor_bottom = top_right_factory.get_right_button().get_path()
		time_control.double_button.focus_neighbor_bottom = top_right_factory.get_right_button().get_path()
	
	
	small_map.focus_neighbor_bottom = top_right_factory.get_right_button().get_path()
	
	var rows : int = ceili(factory_grid.get_child_count() / float(factory_grid.columns))
	for i in range(factory_grid.get_child_count()):
		var factory : FactoryCounter = factory_grid.get_child(i)
		
		# Not against left side
		if i % factory_grid.columns != 0:
			var left_factory : FactoryCounter = factory_grid.get_child(i-1)
			factory.get_left_button().focus_neighbor_left = left_factory.get_right_button().get_path()
		
		# Not against right side
		if i % factory_grid.columns != factory_grid.columns-1:
			var right_factory : FactoryCounter = factory_grid.get_child(i+1)
			factory.get_right_button().focus_neighbor_right = right_factory.get_left_button().get_path()
		
		# Not against top side
		if i / factory_grid.columns != 0:
			var top_factory : FactoryCounter = factory_grid.get_child(i-factory_grid.columns)
			factory.get_left_button().focus_neighbor_top = top_factory.get_left_button().get_path()
			factory.get_right_button().focus_neighbor_top = top_factory.get_right_button().get_path()
		# Against top side
		else:
			factory.get_left_button().focus_neighbor_top = time_control.halve_button.get_path()
			factory.get_right_button().focus_neighbor_top = time_control.halve_button.get_path()
		
		# Not against bottom side
		if i / factory_grid.columns != rows:
			if i+factory_grid.columns < factory_grid.get_child_count():
				var bottom_factory : FactoryCounter = factory_grid.get_child(i+factory_grid.columns)
				factory.get_left_button().focus_neighbor_bottom = bottom_factory.get_left_button().get_path()
				factory.get_right_button().focus_neighbor_bottom = bottom_factory.get_right_button().get_path()

func on_factory_unlocked(factory : FactoryInfo, counter_index : int):
	update_focus_neighbours()
	factory_grid.get_child(counter_index).plan_button.grab_focus()

func _on_solar_system_map_pressed() -> void:
	toggle_large_map()

func _on_minimise_button_pressed() -> void:
	toggle_large_map()

func toggle_large_map():
	large_map_open = !large_map_open
	if large_map_open:
		show_large_map()
	else:
		hide_large_map()
	
	update_focus_neighbours()

func show_large_map():
	large_map.show()
	
	small_map.hide()
	material_window.hide()
	factory_window.hide()
	
	minimise_button.grab_focus()

func hide_large_map():
	large_map.hide()
	
	small_map.show()
	material_window.show()
	factory_window.show()
	
	small_map.grab_focus()
