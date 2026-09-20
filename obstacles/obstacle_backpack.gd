extends Area2D

@export var speed: float = 300.0
@export var backpack_textures: Array[Texture2D] = []

@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	if backpack_textures.size() > 0:
		sprite.texture = backpack_textures[randi() % backpack_textures.size()]

func _process(delta):
	position.x -= speed * delta
	if global_position.x < -200:
		SignalBus.obstacle_passed.emit()
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.on_hit_obstacle()
		queue_free()
