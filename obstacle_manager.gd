extends Node2D

@export var obstacle_scenes: Array[PackedScene] = []
@export var obstacle_ion: PackedScene  # assign obstacle_ion.tscn here specifically
@export var spawn_x_position: float = 2000.0
@export var spawn_y_position: float = 800.0  # adjust to your ground height

@onready var spawn_timer = $SpawnTimer

var spawn_speed_multiplier: float = 1.0
var obstacles_since_last_ion: int = 3  # start at 3 so ion CAN spawn first if picked

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	var scene = _pick_next_obstacle()
	var obstacle = scene.instantiate()
	obstacle.global_position = Vector2(spawn_x_position, spawn_y_position)
	if "speed" in obstacle:
		obstacle.speed *= spawn_speed_multiplier
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
