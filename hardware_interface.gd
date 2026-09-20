extends Node

@onready var http_request = $HTTPRequest
@onready var debug_label = $"../CanvasLayer/Label"

const PHONE_IP = "10.36.83.62"
const DATA_URL = "http://" + PHONE_IP + "/get?accX&accY&accZ"
const START_URL = "http://" + PHONE_IP + "/control?cmd=start"

# 🎯 YOUR PERFECTED HARDWARE VALUES
const JUMP_FORCE_LIMIT = 8.0    
const CHARGE_FORCE_LIMIT = 15.0  
const FLAP_FORCE_THRESHOLD = 5.5       

# 🪶 FLIGHT FLAP ENGINE CONFIGURATIONS (Tuned for instant, non-delayed land drops)
const MAX_SHAKE_ENERGY = 100.0
const ENERGY_GAIN_PER_FLAP = 45.0      
const ENERGY_DECAY_RATE = 80.0         
const FLIGHT_ACTIVE_THRESHOLD = 30.0    

var global_cooldown = 0.0
var landing_lockout = 0.0
var gravity_baseline_z = 0.0
var baseline_samples = 0
const MAX_BASELINE_SAMPLES = 10 
var is_waiting_for_network = false

# UNIFIED SYSTEM STATE VARIABLES
var shake_energy = 0.0
var is_currently_flying = false
var micro_flap_cooldown = 0.0          
var static_time_elapsed = 0.0

# THE SEPARATION ENGINE: Isolates single upward pops from continuous loops
var last_z_direction = 0 
var vector_flip_count = 0
var flip_reset_timer = 0.0

func _ready():
	print("📡 HardwareInterface: Booting up optimized unified wing engine...")
	http_request.request_completed.connect(_on_request_completed)
	var start_check = http_request.request(START_URL)
	if start_check == OK: print("✅ Sent remote START command.")

func _process(delta):
	if global_cooldown > 0.0: global_cooldown -= delta
	if micro_flap_cooldown > 0.0: micro_flap_cooldown -= delta
	if landing_lockout > 0.0: landing_lockout -= delta

	# Decay our historical flip counter over time
	if flip_reset_timer > 0.0:
		flip_reset_timer -= delta
		if flip_reset_timer <= 0.0:
			vector_flip_count = 0

	# Continuous energy tank drain
	if shake_energy > 0.0:
		shake_energy = maxf(0.0, shake_energy - (ENERGY_DECAY_RATE * delta))
	
	# 🦅 FLIGHT STATE ENGINE (Splits animations flawlessly via the SignalBus)
	if not is_currently_flying and shake_energy >= FLIGHT_ACTIVE_THRESHOLD and vector_flip_count >= 2:
		is_currently_flying = true
		print("🦅 HARDWARE STATE: SUSTAINED FLIGHT STARTED!")
		SignalBus.goose_started_flying.emit()
		
	elif is_currently_flying and shake_energy < FLIGHT_ACTIVE_THRESHOLD:
		is_currently_flying = false
		print("🪂 HARDWARE STATE: SUSTAINED FLIGHT STOPPED - DROPPING DOWN!")
		landing_lockout = 0.25 # Protects ground state from landing shock noise
		SignalBus.goose_stopped_flying.emit()

	# Display status panel overlay
	if debug_label != null:
		if is_currently_flying: debug_label.text = "FLYING! Tank: %d%%" % int(shake_energy)
		elif global_cooldown > 0.0 or landing_lockout > 0.0: debug_label.text = "LOCKOUT ACTIVE"
		elif baseline_samples >= MAX_BASELINE_SAMPLES: debug_label.text = "READY"

	if not is_waiting_for_network:
		if http_request.request(DATA_URL) == OK: is_waiting_for_network = true

func _on_request_completed(result, response_code, headers, body):
	is_waiting_for_network = false
	if response_code != 200: return
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK: return
	
	var buffer_data = json.get_data().get("buffer", {})
	var x_arr = buffer_data.get("accX", {}).get("buffer", [])
	var y_arr = buffer_data.get("accY", {}).get("buffer", [])
	var z_arr = buffer_data.get("accZ", {}).get("buffer", [])
	
	if x_arr.size() == 0 or y_arr.size() == 0 or z_arr.size() == 0: return
	if x_arr == null or y_arr == null or z_arr == null: return
	
	var raw_x = float(x_arr[0])
	var raw_y = float(y_arr[0])
	var raw_z = float(z_arr[0])
	
	if baseline_samples < MAX_BASELINE_SAMPLES:
		gravity_baseline_z += raw_z
		baseline_samples += 1
		if baseline_samples == MAX_BASELINE_SAMPLES:
			gravity_baseline_z /= float(MAX_BASELINE_SAMPLES)
			print("✅ Gravity baseline filter initialized.")
		return 
		
	evaluate_physics_triggers(raw_x, raw_y, (raw_z - gravity_baseline_z))

func evaluate_physics_triggers(x: float, y: float, z: float):
	print("RAW VALUES (x: %.2f)(y: %.2f)(z: %.2f)" % [x, y, z])

	var abs_y = abs(y)
	var abs_z = abs(z)
	var max_force = maxf(abs(x), maxf(abs_y, abs_z))
	
	# 🟢 ULTRA-SNAPPY TIMEOUT: If phone is static for just 50ms, clear the tank instantly!
	if max_force < 5.0:
		if is_currently_flying:
			static_time_elapsed += 0.03
			if static_time_elapsed >= 0.05:
				shake_energy = 0.0 
				static_time_elapsed = 0.0
				vector_flip_count = 0
		return

	static_time_elapsed = 0.0
	if global_cooldown > 0.0 or landing_lockout > 0.0: return

	# 🏎️ 1. CHARGE DASH (Y-Axis wins absolute dominance)
	if max_force == abs_y and abs_y > CHARGE_FORCE_LIMIT:
		print("💥 SIGNAL: CHARGE DASH")
		global_cooldown = 0.5
		shake_energy = 0.0 
		vector_flip_count = 0
		SignalBus.goose_charged.emit()
		return

	# 🪶 2. VERTICAL MOVE (Z-Axis wins absolute dominance)
	elif max_force == abs_z:
		
		# Log direction reversals to separate a single flick from a frantic shake
		if z > FLAP_FORCE_THRESHOLD:
			if last_z_direction != 1:
				vector_flip_count += 1
				flip_reset_timer = 0.5 
				last_z_direction = 1
		elif z < -FLAP_FORCE_THRESHOLD:
			if last_z_direction != -1:
				vector_flip_count += 1
				flip_reset_timer = 0.5
				last_z_direction = -1

		# BRANCH A: AIRBORNE RETENTION
		if is_currently_flying:
			if z > FLAP_FORCE_THRESHOLD and micro_flap_cooldown <= 0.0:
				shake_energy = minf(MAX_SHAKE_ENERGY, shake_energy + ENERGY_GAIN_PER_FLAP)
				micro_flap_cooldown = 0.10
			return

		# BRANCH B: GROUNDED TRANSITIONS
		else:
			if z > JUMP_FORCE_LIMIT and global_cooldown <= 0.0:
				# If it's a single isolated lift, execute a crisp JUMP
				if vector_flip_count < 2:
					print("💥 PHONE: DETECTED PURE [ SINGLE JUMP ]")
					global_cooldown = 0.5
					SignalBus.goose_jumped.emit()
					return
				# If they are shaking back-and-forth, bypass jump and trigger takeoff matrix!
				elif micro_flap_cooldown <= 0.0:
					shake_energy = minf(MAX_SHAKE_ENERGY, shake_energy + ENERGY_GAIN_PER_FLAP)
					micro_flap_cooldown = 0.10
