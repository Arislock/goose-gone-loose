extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1700
const FLY_SPEED : int = -1500
const FLY_DURATION : float = 0.8  

const CEILING_Y_LIMIT : float = 100.0  

@onready var sprite = $AnimatedSprite2D
@onready var jump_sound = $JumpSound

var is_attacking := false
var air_action_state := "grounded" 
var flight_timer := 0.0
var is_alive := true

@onready var attack_hitbox = $AttackHitbox

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Catch the boolean argument passed from your hardware core
	SignalBus.goose_jumped.connect(on_hardware_jump_input)
	SignalBus.goose_charged.connect(on_charge)
	attack_hitbox.monitoring = false  # off by default

func _physics_process(delta):
	if not is_alive:
		return
	
	if air_action_state == "flying" and flight_timer > 0.0:
		flight_timer -= delta
		velocity.y = FLY_SPEED
		if flight_timer <= 0.0:
			air_action_state = "jumped" 
	else:
		velocity.y += GRAVITY * delta
	
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("walking")
		air_action_state = "grounded"
		if is_attacking: sprite.play("attacking")
		else: sprite.play("walking")
	else:
		if is_attacking: sprite.play("attacking")
		else:
			if air_action_state == "flying": sprite.play("flying")
			else: sprite.play("jumping")
	
	# Keyboard Fallbacks (Spacebar = regular jump, Up Arrow = simulated shake)
	if Input.is_action_just_pressed("ui_accept"): on_hardware_jump_input(false)
	if Input.is_action_just_pressed("ui_up"): on_hardware_jump_input(true)
	if Input.is_action_just_pressed("ui_right"): on_charge()

	move_and_slide()
	
	if position.y < CEILING_Y_LIMIT:
		position.y = CEILING_Y_LIMIT
		if velocity.y < 0: velocity.y = 0

# --- EXPLICIT ROUTER LAYER ---

# The function parameters now catch the 'is_shake' packet from the bus!
func on_hardware_jump_input(is_shake: bool):
	# 🦘 BRANCH 1: GROUNDED JUMP
	# If you are on the floor, any vertical movement triggers a clean upward launch
	if is_on_floor():
		print("🦢 MECHANICS: Grounded Jump Triggered.")
		air_action_state = "jumped"
		velocity.y = JUMP_SPEED
		jump_sound.play()
		sprite.play("jumping")
		return

	# 🦅 BRANCH 2: AIRBORNE FIXED-TIME FLIGHT
	# If you are anywhere in the air and the phone registers a shake, turn on flight instantly!
	elif not is_on_floor() and is_shake:
		# If we are already flying, ignore duplicate spammed signals so the timer doesn't freeze
		if air_action_state == "flying": 
			return
			
		print("🦅 MECHANICS: Airborne shake confirmed! Activating fixed flight timer loop.")
		air_action_state = "flying"
		flight_timer = FLY_DURATION
		velocity.y = FLY_SPEED
		jump_sound.play()
		sprite.play("flying") # 🎬 Triggers the flight animation instantly!
		return


func on_charge():
	if not is_alive or is_attacking:
		return
	is_attacking = true
	sprite.play("attacking")
	attack_hitbox.monitoring = true  # turn hitbox on during the attack

func _on_animation_finished():
	if sprite.animation == "attacking":
		is_attacking = false
		attack_hitbox.monitoring = false  # turn it back off once attack ends

func on_hit_obstacle():
	print("on_hit_obstacle CALLED")
	if not is_alive:
		print("already dead, skipping")
		return
	is_alive = false
	sprite.play("jumping")
	SignalBus.game_over.emit()
	print("game_over emitted")
	
func _on_body_entered(body):
	print("Collision detected with: ", body.name)
	print("Is in player group: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		body.on_hit_obstacle()
		queue_free()
