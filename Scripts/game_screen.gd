extends TextureRect

var large_map_open : bool = false

@export
var large_map : LargeMap
@export
var material_window : MarginContainer
@export
var factory_window : MarginContainer

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

func show_large_map():
	large_map.show()
	
	material_window.hide()
	factory_window.hide()

func hide_large_map():
	large_map.hide()
	
	material_window.show()
	factory_window.show()
