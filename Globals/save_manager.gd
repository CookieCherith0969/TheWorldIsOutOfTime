extends Node

var game_version : String

var save_path : String = "user://saved_game.tres"

var default_save : SaveGame = SaveGame.new()
var current_save : SaveGame = SaveGame.new()

var has_planets : bool = false
var hash_valid : bool = true

const property_names : Array[String] = [
	"save_version",
	"days_left",
	"end_angle",
	"planet_orbit_angles",
	"planet_rotation_angles",
	"planet_orbit_hours",
	"planet_rotation_hours",
	"asteroid_orbit_angles",
	"asteroid_rotation_angles",
	"asteroid_orbit_hours",
	"asteroid_rotation_hours",
	"death_asteroid_orbit_angle",
	"death_asteroid_rotation_angle",
	"death_asteroid_orbit_hours",
	"death_asteroid_rotation_hours",
	"material_amounts",
	"lifetime_increases",
	"unlocked_factories",
	"factory_build_progresses",
	"active_factory_amounts",
	"planned_factory_amounts",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_version = ProjectSettings.get_setting_with_override("application/config/version")
	default_save = SaveGame.new()
	default_save.save_version = game_version
	default_save.days_left = GameManager.starting_days
	for material in GameManager.Materials:
		default_save.material_amounts.append(0)
		default_save.lifetime_increases.append(0)
	for factory in GameManager.factories:
		default_save.unlocked_factories.append(factory.research_materials.size() <= 0)
		default_save.factory_build_progresses.append(0)
		default_save.active_factory_amounts.append(factory.start_amount)
		default_save.planned_factory_amounts.append(0)
	default_save.hash = generate_hash(default_save)
	current_save = load_save_game()
	if current_save == null:
		reset_save_game()
	if current_save.planet_orbit_angles.size() > 0:
		has_planets = true

func reset_save_game():
	current_save = SaveGame.new()
	
	current_save.save_version = default_save.save_version
	current_save.days_left = default_save.days_left
	
	current_save.material_amounts = default_save.material_amounts.duplicate()
	current_save.lifetime_increases = default_save.lifetime_increases.duplicate()
	
	current_save.unlocked_factories = default_save.unlocked_factories.duplicate()
	current_save.factory_build_progresses = default_save.factory_build_progresses.duplicate()
	current_save.active_factory_amounts = default_save.active_factory_amounts.duplicate()
	current_save.planned_factory_amounts = default_save.planned_factory_amounts.duplicate()
	
	current_save.hash = default_save.hash
	hash_valid = true
	
	has_planets = false

# Loads save from file. Returns the default save game if save isn't valid.
func load_save_game() -> SaveGame:
	if !ResourceLoader.exists(save_path, "SaveGame"):
		push_warning("Save game doesn't exist")
		return null
	var loaded_save : SaveGame = SafeResourceLoader.load(save_path, "SaveGame")
	if !is_instance_valid(loaded_save):
		push_error("Save game failed safety checks")
		return null
	loaded_save = loaded_save.duplicate(true)
	if !is_valid_save(loaded_save):
		return null
	return loaded_save

func is_valid_save(save : SaveGame) -> bool:
	if !is_instance_valid(save):
		push_warning("Save game isn't valid")
		return false
	if save.save_version != game_version:
		push_error("Save game has wrong version")
		return false
	if !"hash" in save:
		push_error("Save lacks a hash")
		hash_valid = false
		#return false
	if save.hash != generate_hash(save):
		push_error("Save game hash mismatch")
		hash_valid = false
		#return false
	
	return true

func current_save_has_planets() -> bool:
	return has_planets

func save_current_game_to_file() -> void:
	ResourceSaver.save(current_save.duplicate(), save_path)
	current_save = SafeResourceLoader.load(save_path, "SaveGame").duplicate()
	if hash_valid:
		current_save.hash = generate_hash(current_save)
	ResourceSaver.save(current_save.duplicate(), save_path)

func generate_hash(save : SaveGame) -> String:
	var hash : String = "Hello, those who have decompiled the game! You've found the hash function! :P"
	
	for property_name in property_names:
		#hash += str(save.get(property_name)).sha256_text()
		hash += str(save.get(property_name))
	
	var hashed : String = hash.sha256_text()
	return hashed

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_current_game_to_file()
