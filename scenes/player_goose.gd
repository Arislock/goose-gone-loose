extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1700
const FLY_SPEED : int = -1200
const FLY_HANG_TIME : float = 0.45

#func _ready():
	#if is_instance_valid(SignalBus):
		#if SignalBus.has_signal("goose_jumped"):
			#SignalBus.goose_jumped.connect(on_jump)

func _ready():
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

var is_attacking := false
var last_launch := "jump"
var fly_timer := 0.0

func _physics_process(delta):
	if last_launch == "fly" and fly_timer > 0.0:
		fly_timer -= delta
		velocity.y = FLY_SPEED
	else:
		velocity.y += GRAVITY * delta
	
	if is_on_floor():
		if Input.is_action_pressed("ui_up"):
			trigger_fly()
		elif Input.is_action_pressed("ui_accept"):
			trigger_jump()
		elif Input.is_action_just_pressed("ui_right") and not is_attacking:
			is_attacking = true
			$AnimatedSprite2D.play("attacking")
		elif not is_attacking:
			$AnimatedSprite2D.play("walking")
	else:
		if last_launch == "fly":
			$AnimatedSprite2D.play("flying")
		else:
			$AnimatedSprite2D.play("jumping")
	
	move_and_slide()

func trigger_jump():
	last_launch = "jump"
	velocity.y = JUMP_SPEED
	$JumpSound.play()
	$AnimatedSprite2D.play("jumping")

func trigger_fly():
	last_launch = "fly"
	fly_timer = FLY_HANG_TIME
	velocity.y = FLY_SPEED
	$JumpSound.play()
	$AnimatedSprite2D.play("flying")

func _on_animation_finished():
	if $AnimatedSprite2D.animation == "attacking":
		is_attacking = false

func on_jump():
	print("SPRITE SCRIPT JUMP")
	trigger_jump()
	
	
