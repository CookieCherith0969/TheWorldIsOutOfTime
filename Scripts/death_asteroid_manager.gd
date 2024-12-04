extends Node2D
class_name DeathAsteroidManager

@export
var earth : MapPlanet
@export
var large_map : LargeMap
@export
var planet_scene : PackedScene

var end_angle : float
@export
var min_end_angle : float = 100.0
@export
var max_end_angle : float = 230.0

var death_asteroid : MapPlanet
@export
var death_asteroid_info : PlanetInfo
var asteroid_start_distance : float
var asteroid_end_distance : float

func _ready():
	GameManager.hour_passed.connect(on_hour_passed)
	create_death_asteroid()
	setup_earth_pos()

func create_death_asteroid():
	end_angle = randf_range(min_end_angle, max_end_angle)
	
	death_asteroid = planet_scene.instantiate()
	death_asteroid.represented_planet = death_asteroid_info
	death_asteroid.should_randomise_rotation = true
	death_asteroid.name = "DeathAsteroid"
	add_sibling.call_deferred(death_asteroid)
	
	var starting_hours : float = GameManager.starting_days*GameManager.hours_per_day
	death_asteroid.orbit_angle = end_angle - 360*(starting_hours/death_asteroid_info.orbital_period_hours)
	death_asteroid.update_position()
	
	asteroid_start_distance = death_asteroid_info.orbit_distance
	asteroid_end_distance = earth.orbit_distance

func setup_earth_pos():
	var starting_hours : float = GameManager.starting_days*GameManager.hours_per_day
	earth.orbit_angle = end_angle - 360*(starting_hours/earth.orbital_period_hours)
	earth.update_position()

func on_hour_passed():
	var death_progress : float = 1.0 - float(GameManager.days_left)/float(GameManager.starting_days)
	var death_asteroid_distance = lerp(asteroid_start_distance, asteroid_end_distance, death_progress)
	death_asteroid.orbit_distance = death_asteroid_distance
	death_asteroid.update_position()
	
	if is_instance_valid(large_map):
		large_map.death_asteroid.orbit_distance = death_asteroid.orbit_distance
		large_map.death_asteroid.update_position()
