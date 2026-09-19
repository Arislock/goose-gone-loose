extends Node2D

@export var obstacle_scenes: Array[PackedScene] = []
@export var spawn_x_position: float = 1300.0
@export var spawn_y_position: float = 500.0  # adjust to your ground height

@onready var spawn_timer = $SpawnTimer

var spawn_speed_multiplier: float = 1.0

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	var scene = obstacle_scenes[randi() % obstacle_scenes.size()]
	var obstacle = scene.instantiate()
	obstacle.global_position = Vector2(spawn_x_position, spawn_y_position)
	if obstacle.has_method("set") and "speed" in obstacle:
		obstacle.speed *= spawn_speed_multiplier
	get_tree().current_scene.add_child(obstacle)
