extends CharacterBody2D

const GRAVITY := 2000.0
const JUMP_VELOCITY := -700.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY

	move_and_slide()
