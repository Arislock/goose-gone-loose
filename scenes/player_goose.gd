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

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Catch the boolean argument passed from your hardware core
	SignalBus.goose_jumped.connect(on_hardware_jump_input)
	SignalBus.goose_charged.connect(on_charge)

func _physics_process(delta):
	if air_action_state == "flying" and flight_timer > 0.0:
		flight_timer -= delta
		velocity.y = FLY_SPEED
		if flight_timer <= 0.0:
			air_action_state = "jumped" 
	else:
		velocity.y += GRAVITY * delta
	
	if is_on_floor():
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
	if not is_attacking:
		is_attacking = true
		sprite.play("attacking")

func _on_animation_finished():
	if sprite.animation == "attacking": is_attacking = false
