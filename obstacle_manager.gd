extends Node2D

@export var obstacle_scenes: Array[PackedScene] = []
@export var obstacle_ion: PackedScene
@export var spawn_x_position: float = 2000.0
@export var spawn_y_position: float = 800.0
@export var base_obstacle_speed: float = 300.0
@export var base_spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.5

@onready var spawn_timer = $SpawnTimer

var spawn_speed_multiplier: float = 1.0
var obstacles_since_last_ion: int = 3

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func update_speed(game_speed: float):
	spawn_speed_multiplier = game_speed / 10.0  # normalized against START_SPEED (10.0)
	spawn_timer.wait_time = max(base_spawn_interval / spawn_speed_multiplier, min_spawn_interval)

func _on_spawn_timer_timeout():
	var camera_x = get_tree().current_scene.get_node("Camera2D").position.x
	var scene = _pick_next_obstacle()
	var obstacle = scene.instantiate()
	obstacle.global_position = Vector2(camera_x + spawn_x_position, spawn_y_position)
	if "speed" in obstacle:
		obstacle.speed = base_obstacle_speed * spawn_speed_multiplier
	get_tree().current_scene.add_child(obstacle)

	if scene == obstacle_ion:
		obstacles_since_last_ion = 0
	else:
		obstacles_since_last_ion += 1

func _pick_next_obstacle() -> PackedScene:
	var pool = obstacle_scenes.duplicate()
	if obstacles_since_last_ion < 3:
		pool.erase(obstacle_ion)
	return pool[randi() % pool.size()]
