extends Node2D

@export
var num_asteroids : int = 10
@onready
var planet_scene : PackedScene = preload("res://Scenes/map_planet.tscn")
@export
var asteroid_info : PlanetInfo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(num_asteroids):
		var new_asteroid = planet_scene.instantiate()
		new_asteroid.represented_planet = asteroid_info
		new_asteroid.should_randomise_position = true
		new_asteroid.should_randomise_rotation = true
		add_sibling.call_deferred(new_asteroid)
