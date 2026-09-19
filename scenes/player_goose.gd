extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1700

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_SPEED
			$JumpSound.play()
		elif Input.is_action_pressed("ui_down"):
			#replace with duck an imation
			$AnimatedSprite2D.play("jumping")
		else: 
			$AnimatedSprite2D.play("walking")
	else:
		$AnimatedSprite2D.play("jumping")
		
	move_and_slide()
