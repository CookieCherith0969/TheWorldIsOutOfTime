extends Resource
class_name SaveGame

@export
var hash : String
@export
var save_version : String

@export
var days_left : int
@export
var end_angle : float

@export
var planet_orbit_angles : Array[float]
@export
var planet_rotation_angles : Array[float]
@export
var planet_orbit_hours : Array[float]
@export
var planet_rotation_hours : Array[float]
@export
var asteroid_orbit_angles : Array[float]
@export
var asteroid_rotation_angles : Array[float]
@export
var asteroid_orbit_hours : Array[float]
@export
var asteroid_rotation_hours : Array[float]
@export
var death_asteroid_orbit_angle : float
@export
var death_asteroid_rotation_angle : float
@export
var death_asteroid_orbit_hours : float
@export
var death_asteroid_rotation_hours : float

@export
var material_amounts : Array[int]
@export
var lifetime_increases : Array[int]

@export
var unlocked_factories : Array[bool]
@export
var factory_build_progresses : Array[int]
@export
var active_factory_amounts : Array[int]
@export
var planned_factory_amounts : Array[int]
