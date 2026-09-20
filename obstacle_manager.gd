extends Node2D

@export var obstacle_scenes: Array[PackedScene] = []
@export var obstacle_ion: PackedScene
@export var obstacle_student: PackedScene
@export var spawn_x_position: float = 2000.0
@export var spawn_y_position: float = 800.0
@export var base_obstacle_speed: float = 300.0
@export var desired_gap_pixels: float = 350.0
@export var min_spawn_interval: float = 0.3

@onready var spawn_timer = $SpawnTimer

var spawn_speed_multiplier: float = 1.0
var obstacles_since_last_ion: int = 3
var last_spawned_scene: PackedScene = null
var skip_next_spawn: bool = false

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func update_speed(game_speed: float):
	spawn_speed_multiplier = game_speed / 10.0
	var current_obstacle_speed = base_obstacle_speed * spawn_speed_multiplier
	var relative_speed = current_obstacle_speed + (game_speed * 60.0)
	spawn_timer.wait_time = max(desired_gap_pixels / relative_speed, min_spawn_interval)

func _on_spawn_timer_timeout():
	if skip_next_spawn:
		skip_next_spawn = false
		return

	var camera_x = get_tree().current_scene.get_node("Camera2D").position.x
	var scene = _pick_next_obstacle()
	var obstacle = scene.instantiate()
	obstacle.global_position = Vector2(camera_x + spawn_x_position, spawn_y_position)
	if "speed" in obstacle:
		obstacle.speed = base_obstacle_speed * spawn_speed_multiplier
	get_tree().current_scene.add_child(obstacle)

	if scene == obstacle_ion:
		obstacles_since_last_ion = 0
		skip_next_spawn = true
	else:
		obstacles_since_last_ion += 1

	last_spawned_scene = scene

func _pick_next_obstacle() -> PackedScene:
	var pool = obstacle_scenes.duplicate()
	if obstacles_since_last_ion < 3:
		pool.erase(obstacle_ion)
	if last_spawned_scene == obstacle_student:
		pool.erase(obstacle_student)
	if pool.is_empty():
		pool = obstacle_scenes.duplicate()
	return pool[randi() % pool.size()]
	
func _on_body_entered(body):
	print("Collision detected with: ", body.name)
	print("Is in player group: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		print("about to call on_hit_obstacle")
		body.on_hit_obstacle()
		queue_free()
