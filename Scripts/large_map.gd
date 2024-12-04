extends NinePatchRect
class_name LargeMap

@export
var small_map : NinePatchRect
@export
var scale_factor : Vector2 = Vector2(2,2)
#var earth : MapPlanet
var death_asteroid : MapPlanet

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_deferred.call_deferred()

func setup_deferred():
	for planet in small_map.get_children():
		if planet is not MapPlanet:
			continue
		
		var dupe_planet : MapPlanet = planet.duplicate()
		dupe_planet.orbit_angle = planet.orbit_angle
		dupe_planet.rotation_angle = planet.rotation_angle
		dupe_planet.orbit_distance = planet.orbit_distance
		dupe_planet.orbital_period_hours = planet.orbital_period_hours
		dupe_planet.rotational_period_hours = planet.rotational_period_hours
		
		dupe_planet.should_randomise_position = false
		dupe_planet.should_randomise_rotation = false
		dupe_planet.map_scale = scale_factor
		add_child(dupe_planet)
		
		if dupe_planet.represented_planet.planet_name == "DEATH ASTEROID":
			death_asteroid = dupe_planet
