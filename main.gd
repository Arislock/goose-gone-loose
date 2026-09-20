extends Node2D

@onready var obstacle_manager = $ObstacleManager

func _ready():
	SignalBus.game_over.connect(_on_game_over)

func _on_game_over():
	obstacle_manager.spawn_timer.stop()
	get_tree().paused = true
	# show a Game Over UI here with Score.current_score displayed,
	# and a restart button that calls get_tree().reload_current_scene()
