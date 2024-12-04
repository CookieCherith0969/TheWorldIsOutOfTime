extends Resource
class_name PlanetInfo

@export
var planet_name : String

@export
var spriteframes : SpriteFrames
@export
var sprite_offset : Vector2 = Vector2.ZERO

@export
var orbital_period_hours : float
@export
var orbit_variation : float = 0.0
@export
var rotational_period_hours : float
@export
var rotation_variation : float = 0.0

@export
var orbit_distance : float
@export
var distance_variation : float = 0.0
