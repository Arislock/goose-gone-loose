extends Node

# game variables
const GOOSE_START_POS := Vector2i(130.0, 838)
const CAM_START_POS := Vector2i(960.0, 540)
var score : int
const SCORE_MODIFIER : int = 10
var speed : float
const START_SPEED : float = 10.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i
var game_running : bool
extends Node2D

@onready var obstacle_manager = $ObstacleManager

func _ready():
	screen_size = get_window().size
	new_game()

func new_game():
	score = 0
	game_running = false
	
	$PlayerGoose.position = GOOSE_START_POS
	$PlayerGoose.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(1440.0,1006)
	
	$HUD.get_node("Start").show()

func _process(delta): 
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		
		# Move goose and camera
		$PlayerGoose.position.x += speed
		$Camera2D.position.x += speed
		
		# Update score
		score += speed
		show_score()
		
		# Update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
	# Just launched game
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("Start").hide()

func show_score():
	$HUD.get_node("Score").text = "SCORE: " + str(score/SCORE_MODIFIER)
	SignalBus.game_over.connect(_on_game_over)

func _on_game_over():
	obstacle_manager.spawn_timer.stop()
	get_tree().paused = true
	# show a Game Over UI here with Score.current_score displayed,
	# and a restart button that calls get_tree().reload_current_scene()
