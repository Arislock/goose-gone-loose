extends Area2D

@export var speed: float = 300.0


func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	var camera_x = get_tree().current_scene.get_node("Camera2D").position.x
	if global_position.x < camera_x - 1000:
		SignalBus.obstacle_passed.emit()
		queue_free()

func _on_body_entered(body):
	print("Collision detected with: ", body.name)
	if body.is_in_group("player"):
		print("Player group confirmed, calling on_hit_obstacle")
		body.on_hit_obstacle()
		queue_free()
