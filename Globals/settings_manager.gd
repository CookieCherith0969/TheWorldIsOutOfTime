extends Node

const save_path : String = "user://settings.txt"

var master_volume : float = 0.5 : set = set_master_volume
var music_volume : float = 0.5 : set = set_music_volume
var effect_volume : float = 0.5 : set = set_effect_volume

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_settings()

func load_settings():
	if !FileAccess.file_exists(save_path):
		master_volume = master_volume
		music_volume = music_volume
		effect_volume = effect_volume
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	master_volume = file.get_float()
	music_volume = file.get_float()
	effect_volume = file.get_float()

func save_settings():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_float(master_volume)
	file.store_float(music_volume)
	file.store_float(effect_volume)

func set_bus_volume(bus_index : int, volume_linear : float):
	match(bus_index):
		0:
			master_volume = volume_linear
		1:
			music_volume = volume_linear
		2:
			effect_volume = volume_linear

func set_master_volume(new_volume : float):
	master_volume = new_volume
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))


func set_music_volume(new_volume : float):
	music_volume = new_volume
	AudioServer.set_bus_volume_db(1, linear_to_db(music_volume))


func set_effect_volume(new_volume : float):
	effect_volume = new_volume
	AudioServer.set_bus_volume_db(2, linear_to_db(effect_volume))
