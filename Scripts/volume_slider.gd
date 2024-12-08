extends HSlider

@export
var bus_name : String
var bus_index : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	var volume_db = AudioServer.get_bus_volume_db(bus_index)
	value = db_to_linear(volume_db)
	value_changed.connect(_on_value_changed)

func _on_value_changed(new_value : float):
	SettingsManager.set_bus_volume(bus_index, new_value)
