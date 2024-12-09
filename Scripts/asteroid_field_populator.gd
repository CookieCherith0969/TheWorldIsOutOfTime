extends Node2D

@export
var num_asteroids : int = 10
@onready
var planet_scene : PackedScene = preload("res://Scenes/map_planet.tscn")
@export
var asteroid_info : PlanetInfo
@export
var map_size : Vector2 = Vector2(200,100)
@export
var map_offset : Vector2 = Vector2(0,50)
@export
var map_scale : Vector2 = Vector2(1,1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(num_asteroids):
		var new_asteroid = planet_scene.instantiate()
		new_asteroid.represented_planet = asteroid_info
		new_asteroid.should_randomise_position = true
		new_asteroid.should_randomise_rotation = true
		new_asteroid.map_size = map_size
		new_asteroid.map_offset = map_offset
		new_asteroid.map_scale = map_scale
		add_sibling.call_deferred(new_asteroid)
