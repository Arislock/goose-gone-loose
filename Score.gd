# Score.gd (autoload)
extends Node

var current_score: int = 0

func _ready():
	SignalBus.obstacle_passed.connect(_on_obstacle_passed)
	SignalBus.game_over.connect(_on_game_over)

func _on_obstacle_passed():
	current_score += 1
	SignalBus.score_updated.emit(current_score)

func _on_game_over():
	pass # score just stops changing naturally since no more obstacles get passed

func reset():
	current_score = 0
