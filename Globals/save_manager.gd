extends Node

var game_version : String

var save_path : String = "user://"

var default_save : SaveGame

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

# Loads save from file. Returns the default save game if save isn't valid.
func load_save_game() -> SaveGame:
	var loaded_save : SaveGame = SafeResourceLoader.load(save_path, "SaveGame")
	if !is_valid_save(loaded_save):
		return default_save
	return loaded_save

func is_valid_save(save : SaveGame) -> bool:
	if !is_instance_valid(save):
		return false
	if save.save_version != game_version:
		return false
	
	return true

func save_current_game_to_file(save : SaveGame) -> void:
	ResourceSaver.save(save, save_path)
