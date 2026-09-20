extends Node

@onready var http_request = $HTTPRequest
@onready var debug_label = $"../CanvasLayer/Label"

const PHONE_IP = "10.36.83.62"

# PHYPHOX NETWORK ENDPOINTS
const DATA_URL = "http://" + PHONE_IP + "/get?accX&accY&accZ"
const START_URL = "http://" + PHONE_IP + "/control?cmd=start"

# ACTION THRESHOLDS
const JUMP_FORCE_LIMIT = 10.0    
const DUCK_FORCE_LIMIT = -10.0   
const CHARGE_FORCE_LIMIT = 10.0  

# Single global cooldown timer variable (when an action is active, it locks other actions)
var global_cooldown = 0.0

# GRAVITY COMPENSATOR VARIABLES
var gravity_baseline_z = 0.0
var baseline_samples = 0
const MAX_BASELINE_SAMPLES = 10 

func _ready():
	print("📡 Initializing Automated Multi-Sensor Engine...")
	http_request.request_completed.connect(_on_request_completed)
	
	# --- DIAGNOSTIC TEST LOOP ---
	# Connect script to global signals
	SignalBus.goose_jumped.connect(_on_diagnostic_jump)
	SignalBus.goose_ducked.connect(_on_diagnostic_duck)
	SignalBus.goose_charged.connect(_on_diagnostic_charge)
	
	# Setup clean onscreen text properties
	#debug_label.text = "STANDBY: Calibrating Gravity..."
	#debug_label.add_theme_font_size_override("font_size", 32)
	#
	# Force the iPhone to start sensing automatically
	var start_check = http_request.request(START_URL)
	if start_check == OK:
		print("✅ Sent remote START command to iPhone. Telemetry spinning up...")
		# small delay
		await get_tree().create_timer(0.5).timeout
	else:
		print("⚠️ Remote start packet failed to send. Check your Wi-Fi network link.")
	
	start_network_loop()

func _process(delta):
	if global_cooldown > 0.0:
		global_cooldown -= delta
		# Display the cooling lockout fraction on screen so you can trace the block window
		debug_label.text = "COOLDOWN ACTIVE: %.2fs" % global_cooldown
	elif baseline_samples >= MAX_BASELINE_SAMPLES:
		# Default text when ready to catch motions
		debug_label.text = "SYSTEM ACTIVE: Perform Movement!"

func start_network_loop():
	while true:
		var error = http_request.request(DATA_URL)
		if error != OK:
			await get_tree().create_timer(0.01).timeout
			continue
		await http_request.request_completed
		await get_tree().create_timer(0.02).timeout


func _on_request_completed(result, response_code, headers, body):
	if response_code != 200: return
	
	var body_string = body.get_string_from_utf8()
	
	# 🔒 CONTROL PACKET FILTER: If this is just a confirmation message from the 
	# start endpoint, skip it entirely and wait for the real sensor numbers!
	if "control" in headers or not "buffer" in body_string:
		return
		
	var json = JSON.new()
	if json.parse(body_string) != OK: return
	
	var data_payload = json.get_data()
	if data_payload == null or not data_payload.has("buffer"): return
	
	var buffer_data = data_payload.get("buffer", {})
	var x_arr = buffer_data.get("accX", {}).get("buffer", [])
	var y_arr = buffer_data.get("accY", {}).get("buffer", [])
	var z_arr = buffer_data.get("accZ", {}).get("buffer", [])
	
	# Double check that arrays actually contain data before extracting index [0]
	if x_arr.size() == 0 or y_arr.size() == 0 or z_arr.size() == 0: return
	if x_arr[0] == null or y_arr[0] == null or z_arr[0] == null: return
	
	var raw_x = float(x_arr[0])
	var raw_y = float(y_arr[0])
	var raw_z = float(z_arr[0])
	
	# 📊 PHASE 1: Auto-detect gravity baseline filter
	if baseline_samples < MAX_BASELINE_SAMPLES:
		gravity_baseline_z += raw_z
		baseline_samples += 1
		print("⏳ Calibrating gravity... Sample %d/%d" % [baseline_samples, MAX_BASELINE_SAMPLES])
		if baseline_samples == MAX_BASELINE_SAMPLES:
			gravity_baseline_z /= float(MAX_BASELINE_SAMPLES)
			print("✅ Gravity Baseline Filter locked at: ", gravity_baseline_z)
		return 
		
	# 📊 PHASE 2: Strip gravity out to restore clean negative vectors
	var localized_z = raw_z - gravity_baseline_z
	
	evaluate_physics_triggers(raw_x, raw_y, localized_z)

func evaluate_physics_triggers(x: float, y: float, z: float):
	if global_cooldown > 0.0: return
	
	# --- 1. CHARGE LOGIC (Forward punch) ---
	if abs(y) > CHARGE_FORCE_LIMIT:
		print("💥 GLOBAL SIGNAL TRIGGERED: CHARGE DASH (Force: %.2f)" % abs(y))
		global_cooldown = 0.5
		SignalBus.goose_charged.emit() # Blast the event globally!
		return
		
	# --- 2. PRIORITY VERTICAL DIRECTION SIEVE (Z-Axis) ---
	if abs(z) > 4.5:
		# Prioritize the positive upward launch phase first to eliminate timing errors
		if z > JUMP_FORCE_LIMIT:
			print("💥 GLOBAL SIGNAL TRIGGERED: JUMP (Force: %.2f)" % z)
			global_cooldown = 0.5 
			SignalBus.goose_jumped.emit()
			return
			
		elif z < DUCK_FORCE_LIMIT:
			print("💥 GLOBAL SIGNAL TRIGGERED: DUCK (Force: %.2f)" % z)
			global_cooldown = 0.5
			SignalBus.goose_ducked.emit()
			return
			
# --- DIAGNOSTIC CALL OUT INTERCEPTORS ---
# These run ONLY when a signal successfully completes a full lap through the SignalBus!
func _on_diagnostic_jump():
	print("🛰️ BUS VERIFIED: goose_jumped event broadcast successfully!")
	debug_label.text = "🔥 BUS SIGNAL CONFIRMED: JUMP! 🔥"

func _on_diagnostic_duck():
	print("🛰️ BUS VERIFIED: goose_ducked event broadcast successfully!")
	debug_label.text = "🔥 BUS SIGNAL CONFIRMED: DUCK! 🔥"

func _on_diagnostic_charge():
	print("🛰️ BUS VERIFIED: goose_charged event broadcast successfully!")
	debug_label.text = "🔥 BUS SIGNAL CONFIRMED: CHARGE DASH! 🔥"
