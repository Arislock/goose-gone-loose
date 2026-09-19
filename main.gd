extends Node2D
extends Node

@onready var http_request = $HTTPRequest

# ⚡ UPDATED DESTINATION NETWORK PROFILE
const PHONE_IP = "10.36.83.62"

# 1. MULTI-SENSOR QUERY: Appending 'sound_level' for real-life acoustic Honking!
const DATA_URL = "http://" + PHONE_IP + "/get?accX&accY&accZ&sound_level"
const START_URL = "http://" + PHONE_IP + "/control?cmd=start"

func _ready():
	print("📡 Initializing Automated Multi-Sensor Engine...")
	http_request.request_completed.connect(_on_request_completed)
	
	# 🤖 REMOTE EXECUTION HACK: Force the iPhone to start streaming automatically!
	var start_check = http_request.request(START_URL)
	if start_check == OK:
		print("✅ Sent remote START command to iPhone. Beginning telemetry...")
		# Wait 0.5 seconds for the phone's hardware chips to warm up and spin up buffers
		await get_tree().create_timer(0.5).timeout
	
	# Transition straight into our self-pacing loop
	start_network_loop()

func start_network_loop():
	while true:
		var error = http_request.request(DATA_URL)
		if error != OK:
			await get_tree().create_timer(0.01).timeout
			continue
		
		await http_request.request_completed
		await get_tree().create_timer(0.02).timeout

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_err = json.parse(body.get_string_from_utf8())
		
		if parse_err == OK:
			var data = json.get_data()
			var buffer_data = data.get("buffer", {})
			
			# Extract standard motion axes
			var x_arr = buffer_data.get("accX", {}).get("buffer", [])
			var y_arr = buffer_data.get("accY", {}).get("buffer", [])
			var z_arr = buffer_data.get("accZ", {}).get("buffer", [])
			
			# Extract our new acoustic mic sensor array
			var mic_arr = buffer_data.get("sound_level", {}).get("buffer", [])
			
			if x_arr.size() > 0 and y_arr.size() > 0 and z_arr.size() > 0:
				var raw_x = x_arr[0]
				var raw_y = y_arr[0]
				var raw_z = z_arr[0]
				
				# Catch mic volume if the array is populated (defaults to 0 if not present)
				var raw_mic = mic_arr[0] if mic_arr.size() > 0 else 0.0
				
				# Display everything unified in the console output
				print("🟢 Motion -> X: %+.2f | Y: %+.2f | Z: %+.2f  📣 Mic Vol: %.1f dB" % [raw_x, raw_y, raw_z, raw_mic])
