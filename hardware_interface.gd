extends Node

@onready var http_request = $HTTPRequest
@onready var debug_label = $"../CanvasLayer/Label"

const PHONE_IP = "10.36.83.62"
const DATA_URL = "http://" + PHONE_IP + "/get?accX&accY&accZ"
const START_URL = "http://" + PHONE_IP + "/control?cmd=start"

# 🎯 SNAPPY EMPIRICAL PROCESSING THRESHOLDS
const JUMP_FORCE_LIMIT = 8.0    
const CHARGE_FORCE_LIMIT = 15.0  

var global_cooldown = 0.0
var gravity_baseline_z = 0.0
var baseline_samples = 0
const MAX_BASELINE_SAMPLES = 10 
var is_waiting_for_network = false

func _ready():
	print("📡 HardwareInterface: Booting up Double-Jump Flight Core...")
	http_request.request_completed.connect(_on_request_completed)
	var start_check = http_request.request(START_URL)
	if start_check == OK: print("✅ Sent remote START command.")

func _process(delta):
	if global_cooldown > 0.0: global_cooldown -= delta

	if debug_label != null:
		if global_cooldown > 0.0: debug_label.text = "LOCKOUT ACTIVE"
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
	
	# 📈 CALCULATE FORCE MAGNITUDE (Your exact vector formula)
	var total_force = sqrt(x*x + y*y + z*z)
	
	if global_cooldown > 0.0: return
	if total_force < 5.0: return

	# 🏎️ 1. CHARGE DASH (Y-Axis dominance)
	if abs_y > CHARGE_FORCE_LIMIT and abs_y > (abs_z * 1.4):
		print("💥 SIGNAL: CHARGE DASH")
		global_cooldown = 0.4
		SignalBus.goose_charged.emit()
		return

	# 🦘 2. JUMP THRESHOLD EVALUATED FIRST (Prevents jumps from being stolen by flight)
	# Triggers when you do a clean, focused vertical pop upward
	if z > JUMP_FORCE_LIMIT and abs_z > abs_y and total_force < 22.0:
		print("💥 GESTURE: PURE UPWARD POP -> JUMP (Force: %.2f)" % z)
		global_cooldown = 0.35 # Slop time lockout window
		SignalBus.goose_jumped.emit(false) # Emit FALSE (Not a shake)
		return

	# 🦅 3. EXPLOSIVE SHAKE THRESHOLD (Raised to prevent accidental triggers)
	# If the total 3D vector magnitude explodes past 22.0, they are definitely shaking the device!
	if total_force > 22.0:
		print("💥 GESTURE: TRUE SHAKE FORCE -> FLIGHT (Magnitude: %.2f)" % total_force)
		global_cooldown = 0.40 # Solid cooldown ensures exactly ONE trigger registers the flight state
		SignalBus.goose_jumped.emit(true) # Emit TRUE (Is a shake)
		return
