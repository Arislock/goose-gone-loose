extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1700
var is_alive: bool = true

func _ready():
	if SignalBus.has_signal("goose_jumped"):
		SignalBus.goose_jumped.connect(on_jump)


func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			trigger_jump()
		elif Input.is_action_pressed("ui_down"):
			#replace with duck an imation
			$AnimatedSprite2D.play("jumping")
		else: 
			$AnimatedSprite2D.play("walking")
	else:
		$AnimatedSprite2D.play("jumping")
		
	move_and_slide()

func trigger_jump():
	velocity.y = JUMP_SPEED
	$JumpSound.play()
	$AnimatedSprite2D.play("jumping")

func on_jump():
	print("SPRITE SCRIPT JUMP")
	trigger_jump()
	
func on_hit_obstacle():
	if not is_alive:
		return
	is_alive = false
	$AnimatedSprite2D.play("crash")
	SignalBus.game_over.emit()
