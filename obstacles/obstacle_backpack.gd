extends Area2D

@export var speed: float = 300.0
@export var min_y_offset: float = 20.0
@export var max_y_offset: float = 100.0
@export var backpack_textures: Array[Texture2D] = []

@onready var sprite = $Sprite2D

func _ready():
	global_position.y += randf_range(min_y_offset, max_y_offset)
	body_entered.connect(_on_body_entered)
	if backpack_textures.size() > 0:
		sprite.texture = backpack_textures[randi() % backpack_textures.size()]

func _process(delta):
	var camera_x = get_tree().current_scene.get_node("Camera2D").position.x
	if global_position.x < camera_x - 2000:
		SignalBus.obstacle_passed.emit()
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.on_hit_obstacle()
		queue_free()
