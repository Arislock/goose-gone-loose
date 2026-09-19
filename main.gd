extends Node2D

@onready var http_request = $HTTPRequest

const PHONE_IP = "10.36.83.62"

# 🛠️ AUTOMATED NETWORK ENDPOINTS
const DATA_URL = "http://" + PHONE_IP + "/get?accX&accY&accZ"
const START_URL = "http://" + PHONE_IP + "/control?cmd=start"

# 🎯 LOCKED-IN HARDCODED EMPIRICAL THRESHOLDS
const JUMP_FORCE_LIMIT = 10.0    
const DUCK_FORCE_LIMIT = -10.0   
const CHARGE_FORCE_LIMIT = 8000.0  

# Single global cooldown timer variable
var global_cooldown = 0.0

# 🌍 GRAVITY COMPENSATOR VARIABLES
var gravity_baseline_z = 0.0
var baseline_samples = 0
const MAX_BASELINE_SAMPLES = 10 

func _ready():
	print("📡 Initializing Automated Multi-Sensor Engine...")
	http_request.request_completed.connect(_on_request_completed)
	
	# 🤖 REMOTE REMOTE START HACK: Force the iPhone to press play automatically!
	var start_check = http_request.request(START_URL)
	if start_check == OK:
		print("✅ Sent remote START command to iPhone. Telemetry spinning up...")
		# Pause for a quick half-second to let the phone spin up its hardware arrays
		await get_tree().create_timer(0.5).timeout
	else:
		print("⚠️ Remote start packet failed to send. Check your Wi-Fi network link.")
	
	# Proceed directly into your self-pacing streaming data loop
	start_network_loop()

func _process(delta):
	if global_cooldown > 0.0:
		global_cooldown -= delta

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
	
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK: return
	
	var buffer_data = json.get_data().get("buffer", {})
	var x_arr = buffer_data.get("accX", {}).get("buffer", [])
	var y_arr = buffer_data.get("accY", {}).get("buffer", [])
	var z_arr = buffer_data.get("accZ", {}).get("buffer", [])
	
	if x_arr.size() == 0 or y_arr.size() == 0 or z_arr.size() == 0: return
	if x_arr[0] == null or y_arr[0] == null or z_arr[0] == null: return
	
	var raw_x = float(x_arr[0])
	var raw_y = float(y_arr[0])
	var raw_z = float(z_arr[0])
	
	# 📊 PHASE 1: Auto-detect gravity baseline filter
	if baseline_samples < MAX_BASELINE_SAMPLES:
		gravity_baseline_z += raw_z
		baseline_samples += 1
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
		return
		
	# --- 2. PRIORITY VERTICAL DIRECTION SIEVE (Z-Axis) ---
	if abs(z) > 4.5:
		# Prioritize the positive upward launch phase first to eliminate timing errors
		if z > JUMP_FORCE_LIMIT:
			print("💥 GLOBAL SIGNAL TRIGGERED: JUMP (Force: %.2f)" % z)
			global_cooldown = 0.5 
			return
			
		elif z < DUCK_FORCE_LIMIT:
			print("💥 GLOBAL SIGNAL TRIGGERED: DUCK (Force: %.2f)" % z)
			global_cooldown = 0.5
			return
