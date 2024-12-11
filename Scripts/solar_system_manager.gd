extends Node2D
class_name SolarSystemManager

## If this value is set, this solar system manager will copy all values from the master, except the map values. This will also sync the planet positions.
@export
var solar_system_master : SolarSystemManager = null

@export
var load_from_file : bool = false
@export
var save_to_file : bool = false

@export
var map_size : Vector2 = Vector2(200,100)
@export
var map_offset : Vector2 = Vector2(0,50)
@export
var map_scale : Vector2 = Vector2(1,1)

@export
var planet_infos : Array[PlanetInfo]
@export
var earth_info : PlanetInfo
@export
var asteroid_info : PlanetInfo
@export
var num_asteroids : int = 30
@export
var planet_scene : PackedScene

@export
var spawn_death_asteroid : bool = false
@export
var death_asteroid_scene : PackedScene
var death_asteroid : MapPlanet
var asteroid_start_distance : float
var asteroid_end_distance : float

var end_angle : float
@export
var min_end_angle : float = 100.0
@export
var max_end_angle : float = 230.0
@export
var asteroid_angle_offset : float = 2.0

var planets : Array[MapPlanet]
var asteroids : Array[MapPlanet]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.day_ended.connect(_on_day_ended)
	if solar_system_master:
		copy_master()
	else:
		setup_planets()
	setup_map_values()
	if save_to_file:
		SaveManager.has_planets = true
		SaveManager.save_current_game_to_file()
	if spawn_death_asteroid:
		update_asteroid_distance()

func setup_planets():
	for i in range(planet_infos.size()):
		var planet_info = planet_infos[i]
		var new_planet : MapPlanet = planet_scene.instantiate()
		new_planet.represented_planet = planet_info
		if load_from_file and SaveManager.current_save_has_planets():
			new_planet.orbit_angle = SaveManager.current_save.planet_orbit_angles[i]
			new_planet.rotation_angle = SaveManager.current_save.planet_rotation_angles[i]
			new_planet.orbital_period_hours = SaveManager.current_save.planet_orbit_hours[i]
			new_planet.rotational_period_hours = SaveManager.current_save.planet_rotation_hours[i]
		else:
			new_planet.randomise_position()
			new_planet.randomise_stats()
			if save_to_file:
				SaveManager.current_save.planet_orbit_angles.append(new_planet.orbit_angle)
				SaveManager.current_save.planet_rotation_angles.append(new_planet.rotation_angle)
				SaveManager.current_save.planet_orbit_hours.append(new_planet.orbital_period_hours)
				SaveManager.current_save.planet_rotation_hours.append(new_planet.rotational_period_hours)
		new_planet.update_position()
		new_planet.update_rotation()
		planets.append(new_planet)
		add_child(new_planet)
	
	var earth : MapPlanet = planet_scene.instantiate()
	earth.represented_planet = earth_info
	if load_from_file and SaveManager.current_save_has_planets():
		earth.orbit_angle = SaveManager.current_save.planet_orbit_angles[planet_infos.size()]
		earth.rotation_angle = SaveManager.current_save.planet_rotation_angles[planet_infos.size()]
		earth.orbital_period_hours = SaveManager.current_save.planet_orbit_hours[planet_infos.size()]
		earth.rotational_period_hours = SaveManager.current_save.planet_rotation_hours[planet_infos.size()]
	else:
		earth.randomise_position()
		earth.randomise_stats()
		if save_to_file:
			#SaveManager.current_save.planet_orbit_angles[planet_infos.size()] = earth.orbit_angle
			SaveManager.current_save.planet_rotation_angles.append(earth.rotation_angle)
			SaveManager.current_save.planet_orbit_hours.append(earth.orbital_period_hours)
			SaveManager.current_save.planet_rotation_hours.append(earth.rotational_period_hours)
		
	if spawn_death_asteroid:
		if load_from_file and SaveManager.current_save_has_planets():
			end_angle = SaveManager.current_save.end_angle
		else:
			end_angle = randf_range(min_end_angle, max_end_angle)
			var starting_hours : float = GameManager.starting_days*GameManager.hours_per_day
			earth.orbit_angle = end_angle - 360*(starting_hours/earth.orbital_period_hours)
			earth.orbit_angle = fposmod(earth.orbit_angle, 360.0)
			if save_to_file:
				SaveManager.current_save.end_angle = end_angle
				SaveManager.current_save.planet_orbit_angles.append(earth.orbit_angle)
		earth.update_position()
		asteroid_end_distance = earth.orbit_distance
	earth.update_rotation()
	planets.append(earth)
	add_child(earth)
	
	populate_asteroids()
	
	if spawn_death_asteroid:
		create_death_asteroid()

func create_death_asteroid():
	death_asteroid = death_asteroid_scene.instantiate()
	death_asteroid.randomise_position()
	death_asteroid.randomise_stats()
	
	if load_from_file and SaveManager.current_save_has_planets():
		death_asteroid.orbit_angle = SaveManager.current_save.death_asteroid_orbit_angle
		death_asteroid.rotation_angle = SaveManager.current_save.death_asteroid_rotation_angle
		death_asteroid.orbital_period_hours = SaveManager.current_save.death_asteroid_orbit_hours
		death_asteroid.rotational_period_hours = SaveManager.current_save.death_asteroid_rotation_hours
	else:
		var starting_hours : float = GameManager.starting_days*GameManager.hours_per_day
		var asteroid_total_orbital_distance = 360*(starting_hours/death_asteroid.represented_planet.orbital_period_hours)
		death_asteroid.orbit_angle = end_angle - asteroid_total_orbital_distance - asteroid_angle_offset
		death_asteroid.orbit_angle = fposmod(death_asteroid.orbit_angle, 360.0)
		if save_to_file:
			SaveManager.current_save.death_asteroid_orbit_angle = death_asteroid.orbit_angle
			SaveManager.current_save.death_asteroid_rotation_angle = death_asteroid.rotation_angle
			SaveManager.current_save.death_asteroid_orbit_hours = death_asteroid.orbital_period_hours
			SaveManager.current_save.death_asteroid_rotation_hours = death_asteroid.rotational_period_hours
	death_asteroid.update_position()
	
	asteroid_start_distance = death_asteroid.represented_planet.orbit_distance
	add_child(death_asteroid)

func copy_master():
	end_angle = solar_system_master.end_angle
	spawn_death_asteroid = solar_system_master.spawn_death_asteroid
	asteroid_start_distance = solar_system_master.asteroid_start_distance
	asteroid_end_distance = solar_system_master.asteroid_end_distance
	if spawn_death_asteroid:
		death_asteroid = death_asteroid_scene.instantiate()
		death_asteroid.copy_planet(solar_system_master.death_asteroid)
		add_child(death_asteroid)
	for planet in solar_system_master.planets:
		var copy_planet : MapPlanet = planet_scene.instantiate()
		copy_planet.copy_planet(planet)
		planets.append(copy_planet)
		add_child(copy_planet)
	for asteroid in solar_system_master.asteroids:
		var copy_asteroid : MapPlanet = planet_scene.instantiate()
		copy_asteroid.copy_planet(asteroid)
		asteroids.append(copy_asteroid)
		add_child(copy_asteroid)

func setup_map_values():
	for planet in planets:
		planet.map_size = map_size
		planet.map_offset = map_offset
		planet.map_scale = map_scale
		planet.update_position()
		planet.update_rotation()
	for asteroid in asteroids:
		asteroid.map_size = map_size
		asteroid.map_offset = map_offset
		asteroid.map_scale = map_scale
		asteroid.update_position()
		asteroid.update_rotation()
	
	if spawn_death_asteroid:
		death_asteroid.map_size = map_size
		death_asteroid.map_offset = map_offset
		death_asteroid.map_scale = map_scale
		death_asteroid.update_position()
		death_asteroid.update_rotation()

func _on_day_ended():
	if spawn_death_asteroid:
		update_asteroid_distance()
	
	if save_to_file:
		update_save_manager()

func update_asteroid_distance():
	var death_progress : float = 1.0 - float(GameManager.days_left)/float(GameManager.starting_days)
	var death_asteroid_distance = lerp(asteroid_start_distance, asteroid_end_distance, death_progress)
	death_asteroid.orbit_distance = death_asteroid_distance
	death_asteroid.update_position()

func populate_asteroids():
	for i in range(num_asteroids):
		var new_asteroid : MapPlanet = planet_scene.instantiate()
		new_asteroid.represented_planet = asteroid_info
		if load_from_file and SaveManager.current_save_has_planets():
			new_asteroid.orbit_angle = SaveManager.current_save.asteroid_orbit_angles[i]
			new_asteroid.rotation_angle = SaveManager.current_save.asteroid_rotation_angles[i]
			new_asteroid.orbital_period_hours = SaveManager.current_save.asteroid_orbit_hours[i]
			new_asteroid.rotational_period_hours = SaveManager.current_save.asteroid_rotation_hours[i]
		else:
			new_asteroid.randomise_position()
			new_asteroid.randomise_stats()
			if save_to_file:
				SaveManager.current_save.asteroid_orbit_angles.append(new_asteroid.orbit_angle)
				SaveManager.current_save.asteroid_rotation_angles.append(new_asteroid.rotation_angle)
				SaveManager.current_save.asteroid_orbit_hours.append(new_asteroid.orbital_period_hours)
				SaveManager.current_save.asteroid_rotation_hours.append(new_asteroid.rotational_period_hours)
		asteroids.append(new_asteroid)
		add_child(new_asteroid)

func update_save_manager():
	for i in range(planets.size()):
		var planet : MapPlanet = planets[i]
		SaveManager.current_save.planet_orbit_angles[i] = planet.orbit_angle
		SaveManager.current_save.planet_rotation_angles[i] = planet.rotation_angle
	
	for i in range(asteroids.size()):
		var asteroid : MapPlanet = asteroids[i]
		SaveManager.current_save.asteroid_orbit_angles[i] = asteroid.orbit_angle
		SaveManager.current_save.asteroid_rotation_angles[i] = asteroid.rotation_angle
	
	SaveManager.current_save.death_asteroid_orbit_angle = death_asteroid.orbit_angle
	SaveManager.current_save.death_asteroid_rotation_angle = death_asteroid.rotation_angle
