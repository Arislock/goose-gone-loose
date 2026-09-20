extends Area2D

@export var speed: float = 300.0
signal defeated

func _ready():
	body_entered.connect(_on_body_entered)
	$AttackZone.area_entered.connect(_on_attacked)

func _process(delta):
	position.x -= speed * delta
	if global_position.x < -200:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.on_hit_obstacle()
		queue_free()

func _on_attacked(area):
	defeated.emit()
	queue_free()
