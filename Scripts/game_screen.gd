extends TextureRect

var large_map_open : bool = false

@export
var small_map : Control
@export
var time_control : TimeControl

@export
var large_map : LargeMap
@export
var large_time_control : TimeControl

@export
var material_window : MaterialWindow

var material_prev : TextureButton
var material_next : TextureButton

@export
var factory_window : FactoryWindow

var factory_grid : GridContainer
var top_left_factory : FactoryCounter
var top_middle_factory : FactoryCounter
var top_right_factory : FactoryCounter
var middle_right_factory : FactoryCounter
var factory_prev : TextureButton
var factory_next : TextureButton

@export
var minimise_button : TextureButton

@export
var launch_button : TextureButton

@export
var death_asteroid_manager : DeathAsteroidManager

@export
var tutorial_popup : TutorialPopup

var tutorial_texts : Array[String] = [
	"Hello, World.",
	"An asteroid is heading towards Earth.",
	"You have 9 years to stop it.",
	"You control when time progresses.",
	"You must launch a rocket to destroy the asteroid. The rocket needs materials.",
	"This window tracks your stocks and (projected) production of each material. Materials are produced by factories.",
	"This window tracks the built and planned amounts of each factory. Most factories output daily once built.",
	"The numbers above the material icons indicate the daily input and output of the factory.",
	"Factories cost materials to research, and to build.",
	"Some factories run upon being built, instead of daily. These factories lack numbers above their inputs.",
	"The fate of Earth lies in your hands. Good luck."
]

var tutorial_positions : Array[Vector2i] = [
	Vector2i(250,250),
	Vector2i(200,300),
	Vector2i(200,200),
	Vector2i(340,200),
	Vector2i(200,200),
	Vector2i(150,300),
	Vector2i(400,150),
	Vector2i(250,170),
	Vector2i(350,200),
	Vector2i(250,160),
	Vector2i(250,250),
]

var tutorial_targets : Array[Vector2i] = [
	Vector2i(250,250),
	Vector2i(0,0),
	Vector2i(200,37),
	Vector2i(218,69),
	Vector2i(78,69),
	Vector2i(150,203),
	Vector2i(350,210),
	Vector2i(305,224),
	Vector2i(400,300),
	Vector2i(290,224),
	Vector2i(250,250),
]

@export
var tutorial_elements : Array[Control] = []

var tutorial_index : int = 0

@export
var screen_cover : ColorRect

func _ready() -> void:
	#small_map.grab_focus()
	UIManager.set_focus_target(small_map)
	
	material_prev = material_window.prev_button
	material_next = material_window.next_button
	
	factory_grid = factory_window.factory_grid
	top_left_factory = factory_grid.get_child(0)
	top_middle_factory = factory_grid.get_child(factory_grid.columns/2)
	top_right_factory = factory_grid.get_child(factory_grid.columns-1)
	middle_right_factory = factory_grid.get_child(factory_grid.columns-1 + factory_grid.columns)
	factory_prev = factory_window.prev_button
	factory_next = factory_window.next_button
	
	for factory in factory_grid.get_children():
		factory.factory_unlocked.connect(on_factory_unlocked)
	
	setup_focus_neighbours()
	update_focus_neighbours()
	
	factory_window.page_changed.connect(on_factory_page_changed)
	GameManager.update_predicted_changes()
	
	for child in get_children():
		child.hide()
	
	tutorial_popup.popup_dismissed.connect(on_popup_dismissed)
	
	setup_popup.call_deferred()

func setup_popup():
	tutorial_targets[1] = Vector2i(death_asteroid_manager.death_asteroid.global_position + death_asteroid_manager.warning_offset)
	show_tutorial_popup(0)

func on_popup_dismissed():
	print("popup dismissed")
	tutorial_index += 1
	if tutorial_index >= tutorial_texts.size():
		GameManager.game_state = GameManager.GameState.GAME
		tutorial_popup.hide()
		small_map.disabled = false
		small_map.grab_focus()
		factory_window.prev_page()
		material_window.prev_page(false)
		screen_cover.hide()
		time_control.update_buttons()
		return
	
	show_tutorial_popup(tutorial_index)

func show_tutorial_popup(index : int):
	tutorial_popup.show()
	screen_cover.show()
	tutorial_popup.grab_focus()
	tutorial_popup.set_text(tutorial_texts[tutorial_index])
	tutorial_popup.set_center_position(tutorial_positions[tutorial_index])
	tutorial_popup.set_target(tutorial_targets[tutorial_index])
	tutorial_elements[tutorial_index].show()
	if index == 8:
		middle_right_factory.show_tooltip()
	elif index == 9:
		UIManager.hide_tooltip()
		factory_window.next_page()

func on_factory_page_changed():
	update_focus_neighbours()

func setup_focus_neighbours():
	small_map.focus_neighbor_left = time_control.timeskip_button.get_path()
	time_control.timeskip_button.focus_neighbor_right = small_map.get_path()
	#material_prev.focus_neighbor_top = launch_button.get_path()
	#material_next.focus_neighbor_top = time_control.timeskip_button.get_path()
	#time_control.halve_button.focus_neighbor_bottom = material_prev.get_path()
	#time_control.double_button.focus_neighbor_bottom = material_next.get_path()
	#time_control.timeskip_button.focus_neighbor_bottom = material_next.get_path()
	
	minimise_button.focus_neighbor_left = large_time_control.timeskip_button.get_path()
	large_time_control.halve_button.focus_neighbor_bottom = minimise_button.get_path()
	large_time_control.double_button.focus_neighbor_bottom = minimise_button.get_path()
	large_time_control.timeskip_button.focus_neighbor_right = minimise_button.get_path()
	large_time_control.timeskip_button.focus_neighbor_bottom = minimise_button.get_path()

func update_focus_neighbours():
	material_prev.focus_neighbor_bottom = top_left_factory.get_left_button().get_path()
	material_next.focus_neighbor_bottom = top_middle_factory.get_right_button().get_path()
	material_next.focus_next = top_left_factory.get_left_button().get_path()
	top_left_factory.get_left_button().focus_previous = material_next.get_path()
	small_map.focus_neighbor_bottom = top_right_factory.get_right_button().get_path()
	
	var rows : int = ceili(factory_grid.get_child_count() / float(factory_grid.columns))
	for i in range(factory_grid.get_child_count()):
		var factory : FactoryCounter = factory_grid.get_child(i)
		
		# Not against left side
		if i % factory_grid.columns != 0:
			var left_factory : FactoryCounter = factory_grid.get_child(i-1)
			factory.get_left_button().focus_neighbor_left = left_factory.get_right_button().get_path()
			factory.get_left_button().focus_previous = left_factory.get_right_button().get_path()
		# Against left side
		else:
			factory.get_left_button().focus_neighbor_left = factory.get_left_button().get_path()
			if i-1 >= 0:
				var prev_factory : FactoryCounter = factory_grid.get_child(i-1)
				factory.get_left_button().focus_previous = prev_factory.get_right_button().get_path()
		
		if i >= GameManager.factories.size():
			factory.get_right_button().focus_neighbor_right = factory.get_right_button().get_path()
		# Not against right side
		elif i % factory_grid.columns != factory_grid.columns-1:
			var right_factory : FactoryCounter = factory_grid.get_child(i+1)
			factory.get_right_button().focus_neighbor_right = right_factory.get_left_button().get_path()
			factory.get_right_button().focus_next = right_factory.get_left_button().get_path()
		# Against right side
		else:
			factory.get_right_button().focus_neighbor_right = factory.get_right_button().get_path()
			factory.get_right_button().focus_next = factory_prev.get_path()
			if i+1 < factory_grid.get_child_count():
				var next_factory : FactoryCounter = factory_grid.get_child(i+1)
				if !next_factory.empty:
					factory.get_right_button().focus_next = next_factory.get_left_button().get_path()
		
		# Not against top side
		if i / factory_grid.columns != 0:
			var top_factory : FactoryCounter = factory_grid.get_child(i-factory_grid.columns)
			factory.get_left_button().focus_neighbor_top = top_factory.get_left_button().get_path()
			factory.get_right_button().focus_neighbor_top = top_factory.get_right_button().get_path()
		# Against top side
		else:
			if i % factory_grid.columns == 0:
				factory.get_left_button().focus_neighbor_top = material_prev.get_path()
				factory.get_right_button().focus_neighbor_top = material_prev.get_path()
			elif i % factory_grid.columns == 1:
				factory.get_left_button().focus_neighbor_top = material_next.get_path()
				factory.get_right_button().focus_neighbor_top = material_next.get_path()
			else:
				factory.get_left_button().focus_neighbor_top = small_map.get_path()
				factory.get_right_button().focus_neighbor_top = small_map.get_path()
		
		# Not against bottom side
		if i / factory_grid.columns != rows:
			if i+factory_grid.columns < factory_grid.get_child_count():
				var bottom_factory : FactoryCounter = factory_grid.get_child(i+factory_grid.columns)
				if bottom_factory.empty:
					if i % factory_grid.columns == 0:
						factory.get_left_button().focus_neighbor_bottom = factory_prev.get_path()
						factory.get_right_button().focus_neighbor_bottom = factory_prev.get_path()
					else:
						factory.get_left_button().focus_neighbor_bottom = factory_next.get_path()
						factory.get_right_button().focus_neighbor_bottom = factory_next.get_path()
				else:
					factory.get_left_button().focus_neighbor_bottom = bottom_factory.get_left_button().get_path()
					factory.get_right_button().focus_neighbor_bottom = bottom_factory.get_right_button().get_path()

func on_factory_unlocked(_factory : FactoryInfo, counter_index : int):
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
	UIManager.print_to_code_window("show_large_map()")
	large_time_control.selected_exponent = time_control.selected_exponent
	large_time_control.update_label()
	large_time_control.update_buttons()
	
	large_map.show()
	large_time_control.show()
	
	small_map.hide()
	material_window.hide()
	factory_window.hide()
	time_control.hide()
	launch_button.hide()
	
	minimise_button.grab_focus()

func hide_large_map():
	UIManager.print_to_code_window("hide_large_map()")
	time_control.selected_exponent = large_time_control.selected_exponent
	time_control.update_label()
	time_control.update_buttons()
	
	large_map.hide()
	large_time_control.hide()
	
	small_map.show()
	material_window.show()
	factory_window.show()
	time_control.show()
	launch_button.show()
	
	small_map.grab_focus()
