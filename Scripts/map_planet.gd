extends AnimatedSprite2D
class_name MapPlanet

@export
var represented_planet : PlanetInfo
const planet_scene : PackedScene = preload("res://Scenes/map_planet.tscn")

@export
var map_size : Vector2 = Vector2(200,100)
@export
var map_offset : Vector2 = Vector2(0,50)
@export
var map_scale : Vector2 = Vector2(1,1)

const rotation_divisor : float = 32.0 # Ideally a power of 2
#const rotation_multiplier : float = 1/rotation_divisor

var orbit_angle : float = 0.0
var rotation_angle : float = 0.0

var orbit_distance : float = 0.0
var orbital_period_hours : float = 0.0
var rotational_period_hours : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.day_ended.connect(on_day_ended)
	sprite_frames = represented_planet.sprite_frame_list.pick_random()
	name = represented_planet.planet_name
	
	orbit_distance = represented_planet.orbit_distance
	orbital_period_hours = represented_planet.orbital_period_hours
	rotational_period_hours = represented_planet.rotational_period_hours
	#randomise_stats()
	update_position()
	update_rotation()

func randomise_position():
	orbit_angle = randf_range(0.0, 360.0)
	rotation_angle = randf_range(0.0, 360.0*rotation_divisor)

func randomise_stats():
	var half_distance_variation = represented_planet.distance_variation/2
	orbit_distance = represented_planet.orbit_distance + randf_range(-half_distance_variation, half_distance_variation)
	var half_orbit_variation = represented_planet.orbit_variation/2
	orbital_period_hours = represented_planet.orbital_period_hours + randf_range(-half_orbit_variation, half_orbit_variation)
	var half_rotation_variation = represented_planet.rotation_variation/2
	rotational_period_hours = represented_planet.rotational_period_hours + randf_range(-half_rotation_variation, half_rotation_variation)

func on_day_ended():
	if orbital_period_hours > 0:
		var orbit_change = 1/orbital_period_hours
		orbit_angle += 360*orbit_change*24
		orbit_angle = fposmod(orbit_angle, 360.0)
		update_position()
	
	if rotational_period_hours > 0:
		var rotate_change = 1/rotational_period_hours
		rotation_angle += 360*rotate_change*24
		rotation_angle = fposmod(rotation_angle, 360.0*rotation_divisor)
		update_rotation()

func update_position():
	var center: Vector2 = map_size/2 + map_offset
	center *= map_scale
	
	var working_position: Vector2 = Vector2.from_angle(deg_to_rad(orbit_angle))
	if map_size.y < map_size.x:
		working_position.y *= map_size.y/map_size.x
	
	working_position *= orbit_distance
	working_position *= map_scale
	working_position += center
	working_position += represented_planet.sprite_offset
	
	position = working_position
	
	if orbital_period_hours <= 0:
		return
	if orbit_angle < 180:
		z_index = 3
	else:
		z_index = 1
		

func update_rotation():
	var frame_count = sprite_frames.get_frame_count("default")
	var frame_angle = 360 / frame_count
	frame = int(rotation_angle/(frame_angle*rotation_divisor)) % frame_count

func make_clone():
	var clone : MapPlanet = planet_scene.instantiate()
	clone.represented_planet = represented_planet
	clone.map_size = map_size
	clone.map_offset = map_offset
	clone.map_scale = map_scale
	clone.orbit_angle = orbit_angle
	clone.rotation_angle = rotation_angle
	clone.orbit_distance = orbit_distance
	clone.orbital_period_hours = orbital_period_hours
	clone.rotational_period_hours = rotational_period_hours
	return clone

func copy_planet(other : MapPlanet):
	represented_planet = other.represented_planet
	map_size = other.map_size
	map_offset = other.map_offset
	map_scale = other.map_scale
	orbit_angle = other.orbit_angle
	rotation_angle = other.rotation_angle
	orbit_distance = other.orbit_distance
	orbital_period_hours = other.orbital_period_hours
	rotational_period_hours = other.rotational_period_hours
