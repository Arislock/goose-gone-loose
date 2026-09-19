extends Area2D

@export var speed: float = 300.0

func _process(delta):
	position.x -= speed * delta
	if global_position.x < -200:
		queue_free()
