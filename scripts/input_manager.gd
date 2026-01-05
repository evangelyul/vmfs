extends Node

## Input Manager - Handles HOTAS and multiple controller support
## Autoload singleton for global input handling

signal controller_connected(device_id: int, device_name: String)
signal controller_disconnected(device_id: int)

# Default axis indices for common flight sticks
const DEFAULT_ROLL_AXIS: int = 0      # Stick X
const DEFAULT_PITCH_AXIS: int = 1     # Stick Y
const DEFAULT_YAW_AXIS: int = 2       # Twist or rudder pedals
const DEFAULT_THROTTLE_AXIS: int = 3  # Throttle lever

# Axis configuration class
class AxisConfig:
	var roll_axis: int = DEFAULT_ROLL_AXIS
	var pitch_axis: int = DEFAULT_PITCH_AXIS
	var yaw_axis: int = DEFAULT_YAW_AXIS
	var throttle_axis: int = DEFAULT_THROTTLE_AXIS
	var roll_inverted: bool = false
	var pitch_inverted: bool = true  # Most sticks: pull back = positive
	var yaw_inverted: bool = false
	var throttle_inverted: bool = true  # Most throttles: forward = max
	var deadzone: float = 0.1
	var sensitivity: float = 1.0

# Axis mappings (device_id -> axis configuration)
var axis_mappings: Dictionary = {}
var connected_devices: Dictionary = {}  # device_id -> device_name
var primary_flight_stick: int = -1
var primary_throttle_device: int = -1

# Cached input values
var stick_roll: float = 0.0
var stick_pitch: float = 0.0
var stick_yaw: float = 0.0
var stick_throttle: float = 0.0
var use_analog_throttle: bool = false

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_detect_connected_devices()
	_load_axis_mappings()

func _detect_connected_devices() -> void:
	var devices = Input.get_connected_joypads()
	for device_id in devices:
		_register_device(device_id)

func _register_device(device_id: int) -> void:
	var device_name = Input.get_joy_name(device_id)
	connected_devices[device_id] = device_name

	# Create default axis config for this device
	if not axis_mappings.has(device_id):
		axis_mappings[device_id] = _create_default_config(device_name)

	# Auto-assign primary devices
	if primary_flight_stick == -1:
		if _is_flight_stick(device_name):
			primary_flight_stick = device_id
			print("Primary flight stick: %s (device %d)" % [device_name, device_id])
		elif _is_gamepad(device_name):
			primary_flight_stick = device_id
			print("Using gamepad as flight stick: %s (device %d)" % [device_name, device_id])

	if primary_throttle_device == -1:
		if _is_throttle_device(device_name):
			primary_throttle_device = device_id
			print("Primary throttle: %s (device %d)" % [device_name, device_id])

	emit_signal("controller_connected", device_id, device_name)

func _is_flight_stick(device_name: String) -> bool:
	var lower = device_name.to_lower()
	return "stick" in lower or "joystick" in lower or "hotas" in lower or \
		   "t.16000" in lower or "t16000" in lower or "x52" in lower or \
		   "x56" in lower or "warthog" in lower or "gladiator" in lower or \
		   "virpil" in lower or "vkb" in lower

func _is_throttle_device(device_name: String) -> bool:
	var lower = device_name.to_lower()
	return "throttle" in lower or "twcs" in lower

func _is_gamepad(device_name: String) -> bool:
	var lower = device_name.to_lower()
	return "xbox" in lower or "playstation" in lower or "ps4" in lower or \
		   "ps5" in lower or "dualshock" in lower or "dualsense" in lower or \
		   "controller" in lower or "gamepad" in lower

func _create_default_config(device_name: String) -> AxisConfig:
	var config = AxisConfig.new()
	var lower = device_name.to_lower()

	# Known device profiles
	if "t.16000" in lower or "t16000" in lower:
		config.yaw_axis = 2  # Twist
		config.throttle_axis = 3
		config.pitch_inverted = true
	elif "x52" in lower or "x56" in lower:
		config.yaw_axis = 5
		config.throttle_axis = 2
		config.pitch_inverted = true
	elif "warthog" in lower:
		config.yaw_axis = 2
		config.throttle_axis = 3
		config.pitch_inverted = true
	elif _is_gamepad(device_name):
		# Standard gamepad mapping
		config.roll_axis = 0      # Left stick X
		config.pitch_axis = 1     # Left stick Y
		config.yaw_axis = 2       # Right stick X
		config.throttle_axis = 5  # Right trigger for throttle up
		config.pitch_inverted = true
		config.throttle_inverted = false

	return config

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_register_device(device_id)
	else:
		connected_devices.erase(device_id)
		axis_mappings.erase(device_id)
		if device_id == primary_flight_stick:
			primary_flight_stick = -1
			# Try to find another device
			for id in connected_devices:
				if _is_flight_stick(connected_devices[id]) or _is_gamepad(connected_devices[id]):
					primary_flight_stick = id
					break
		if device_id == primary_throttle_device:
			primary_throttle_device = -1
		emit_signal("controller_disconnected", device_id)

func _process(_delta: float) -> void:
	_update_stick_inputs()

func _update_stick_inputs() -> void:
	stick_roll = 0.0
	stick_pitch = 0.0
	stick_yaw = 0.0

	# Read from primary flight stick
	if primary_flight_stick >= 0 and axis_mappings.has(primary_flight_stick):
		var config: AxisConfig = axis_mappings[primary_flight_stick]

		stick_roll = _get_axis_with_config(primary_flight_stick, config.roll_axis,
											config.roll_inverted, config.deadzone)
		stick_pitch = _get_axis_with_config(primary_flight_stick, config.pitch_axis,
											 config.pitch_inverted, config.deadzone)
		stick_yaw = _get_axis_with_config(primary_flight_stick, config.yaw_axis,
										   config.yaw_inverted, config.deadzone)

		# Apply sensitivity
		stick_roll *= config.sensitivity
		stick_pitch *= config.sensitivity
		stick_yaw *= config.sensitivity

	# Read throttle from primary throttle device (or stick if same device)
	var throttle_device = primary_throttle_device if primary_throttle_device >= 0 else primary_flight_stick
	if throttle_device >= 0 and axis_mappings.has(throttle_device):
		var config: AxisConfig = axis_mappings[throttle_device]
		var raw_throttle = Input.get_joy_axis(throttle_device, config.throttle_axis)

		if absf(raw_throttle) > 0.05:  # Throttle axis is being used
			use_analog_throttle = true
			if config.throttle_inverted:
				raw_throttle = -raw_throttle
			# Convert from -1..1 to 0..1
			stick_throttle = clampf((raw_throttle + 1.0) / 2.0, 0.0, 1.0)

func _get_axis_with_config(device: int, axis: int, inverted: bool, deadzone: float) -> float:
	var value = Input.get_joy_axis(device, axis)

	# Apply deadzone
	if absf(value) < deadzone:
		return 0.0

	# Rescale to use full range outside deadzone
	var sign_val = signf(value)
	value = (absf(value) - deadzone) / (1.0 - deadzone) * sign_val

	if inverted:
		value = -value

	return clampf(value, -1.0, 1.0)

func get_roll_input() -> float:
	return stick_roll

func get_pitch_input() -> float:
	return stick_pitch

func get_yaw_input() -> float:
	return stick_yaw

func get_throttle_value() -> float:
	return stick_throttle

func is_using_analog_throttle() -> bool:
	return use_analog_throttle

func has_controller() -> bool:
	return primary_flight_stick >= 0

func get_controller_name() -> String:
	if primary_flight_stick >= 0 and connected_devices.has(primary_flight_stick):
		return connected_devices[primary_flight_stick]
	return "None"

# Settings persistence
func save_axis_mappings() -> void:
	var config = ConfigFile.new()
	for device_id in axis_mappings:
		var mapping: AxisConfig = axis_mappings[device_id]
		var section = "device_%d" % device_id
		config.set_value(section, "roll_axis", mapping.roll_axis)
		config.set_value(section, "pitch_axis", mapping.pitch_axis)
		config.set_value(section, "yaw_axis", mapping.yaw_axis)
		config.set_value(section, "throttle_axis", mapping.throttle_axis)
		config.set_value(section, "roll_inverted", mapping.roll_inverted)
		config.set_value(section, "pitch_inverted", mapping.pitch_inverted)
		config.set_value(section, "yaw_inverted", mapping.yaw_inverted)
		config.set_value(section, "throttle_inverted", mapping.throttle_inverted)
		config.set_value(section, "deadzone", mapping.deadzone)
		config.set_value(section, "sensitivity", mapping.sensitivity)
	config.save("user://input_config.cfg")

func _load_axis_mappings() -> void:
	var config = ConfigFile.new()
	if config.load("user://input_config.cfg") == OK:
		for section in config.get_sections():
			var device_id = int(section.replace("device_", ""))
			var mapping = AxisConfig.new()
			mapping.roll_axis = config.get_value(section, "roll_axis", DEFAULT_ROLL_AXIS)
			mapping.pitch_axis = config.get_value(section, "pitch_axis", DEFAULT_PITCH_AXIS)
			mapping.yaw_axis = config.get_value(section, "yaw_axis", DEFAULT_YAW_AXIS)
			mapping.throttle_axis = config.get_value(section, "throttle_axis", DEFAULT_THROTTLE_AXIS)
			mapping.roll_inverted = config.get_value(section, "roll_inverted", false)
			mapping.pitch_inverted = config.get_value(section, "pitch_inverted", true)
			mapping.yaw_inverted = config.get_value(section, "yaw_inverted", false)
			mapping.throttle_inverted = config.get_value(section, "throttle_inverted", true)
			mapping.deadzone = config.get_value(section, "deadzone", 0.1)
			mapping.sensitivity = config.get_value(section, "sensitivity", 1.0)
			axis_mappings[device_id] = mapping
