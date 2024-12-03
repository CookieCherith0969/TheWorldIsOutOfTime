extends AnimatedSprite2D

@export
var represented_planet : PlanetInfo

const map_size : Vector2 = Vector2(200,100)
const map_offset : Vector2 = Vector2(0,50)
const rotation_divisor : float = 32.0 # Ideally a power of 2
#const rotation_multiplier : float = 1/rotation_divisor

var orbit_angle : float = randf_range(0.0, 360.0)
var rotation_angle : float = randf_range(0.0, 360.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.hour_passed.connect(on_hour_passed)
	sprite_frames = represented_planet.spriteframes
	update_position()
	update_rotation()

func on_hour_passed():
	if represented_planet.orbital_period_hours > 0:
		var orbit_change = 1/represented_planet.orbital_period_hours
		orbit_angle += 360*orbit_change
		orbit_angle = fposmod(orbit_angle, 360.0)
		update_position()
	
	if represented_planet.rotational_period_hours > 0:
		var rotate_change = 1/represented_planet.rotational_period_hours
		rotation_angle += 360*rotate_change
		rotation_angle = fposmod(rotation_angle, 360.0*rotation_divisor)
		update_rotation()

func update_position():
	var center: Vector2 = map_size/2 + map_offset
	
	var working_position: Vector2 = Vector2.from_angle(deg_to_rad(orbit_angle))
	if map_size.y < map_size.x:
		working_position.y *= map_size.y/map_size.x
	
	working_position *= represented_planet.orbit_distance
	working_position += center
	working_position += represented_planet.sprite_offset
	
	position = working_position
	
	if represented_planet.orbital_period_hours <= 0:
		return
	if orbit_angle < 180:
		z_index = 2
	else:
		z_index = 0
		

func update_rotation():
	frame = int(rotation_angle/(45*rotation_divisor))%8
