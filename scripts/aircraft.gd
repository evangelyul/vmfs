extends CharacterBody3D

## Flight Model - Cessna 152
## Reference: C152 Data Sheet.pdf

# Physical properties (C152 at max takeoff weight)
@export var mass_kg: float = 757.0  # 1670 lbs max takeoff
@export var wing_area_m2: float = 14.9  # C152 wing area
@export var wing_span_m: float = 10.2  # C152 wingspan
@export var thrust_max_n: float = 2400.0  # 108 BHP ≈ 80kW, ~2400N static thrust
@export var drag_coefficient: float = 0.027
@export var lift_coefficient_base: float = 0.35
@export var lift_coefficient_per_aoa: float = 0.1

# Control authority (degrees/sec at cruise)
@export var pitch_rate: float = 30.0  # deg/sec at full deflection
@export var roll_rate: float = 45.0   # deg/sec at full deflection
@export var yaw_rate: float = 15.0    # deg/sec at full deflection

# Control input acceleration (how fast controls move to target)
@export var control_acceleration: float = 2.0  # units per second (0-1 range)

# V-speeds (from C152 data sheet)
@export var vso_kts: float = 35.0   # Stall speed landing config
@export var vs1_kts: float = 40.0   # Stall speed cruise config
@export var vne_kts: float = 149.0  # Never exceed
@export var vno_kts: float = 111.0  # Max structural cruise
@export var va_kts: float = 104.0   # Maneuvering speed
@export var vy_kts: float = 67.0    # Best rate of climb
@export var vx_kts: float = 55.0    # Best angle of climb

# Stall parameters
@export var stall_aoa_deg: float = 16.0
@export var critical_aoa_deg: float = 12.0  # Lift starts reducing

# State
var throttle: float = 0.8

# Control inputs (target values from keyboard)
var pitch_target: float = 0.0
var roll_target: float = 0.0
var yaw_target: float = 0.0

# Actual control positions (smoothed)
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

# Flight data (for HUD and FDR)
var airspeed_mps: float = 0.0
var airspeed_kts: float = 0.0
var altitude_m: float = 0.0
var altitude_ft: float = 0.0
var vertical_speed_mps: float = 0.0
var vertical_speed_fpm: float = 0.0
var heading_deg: float = 0.0
var pitch_deg: float = 0.0
var roll_deg: float = 0.0
var aoa_deg: float = 0.0
var g_load: float = 1.0

# Position (for FDR)
var latitude: float = 37.9487
var longitude: float = 23.9447

# Internal
var aircraft_velocity: Vector3 = Vector3.ZERO
const GRAVITY: float = 9.81
const KTS_TO_MPS: float = 0.514444
const MPS_TO_KTS: float = 1.94384
const M_TO_FT: float = 3.28084
const MPS_TO_FPM: float = 196.85

# Model references
var external_model: Node3D = null
var cockpit_model: Node3D = null
var is_cockpit_view: bool = false

signal view_changed(is_cockpit: bool)

func _ready() -> void:
	# Start with initial velocity (~90 kts - typical cruise)
	var initial_speed = 90.0 * KTS_TO_MPS
	aircraft_velocity = -global_transform.basis.z * initial_speed

	# Find model nodes
	external_model = get_node_or_null("ExternalModel")
	cockpit_model = get_node_or_null("CockpitModel")

	# Start in external view
	set_view_mode(false)

func set_view_mode(cockpit: bool) -> void:
	is_cockpit_view = cockpit
	if external_model:
		external_model.visible = not cockpit
	if cockpit_model:
		cockpit_model.visible = cockpit
	emit_signal("view_changed", cockpit)

func _physics_process(delta: float) -> void:
	process_input(delta)
	update_control_positions(delta)
	calculate_flight_parameters()
	apply_aerodynamics(delta)
	apply_controls(delta)
	apply_movement(delta)
	update_position_coords(delta)
	check_overspeed()

func process_input(delta: float) -> void:
	# Throttle (Shift/Ctrl)
	if Input.is_action_pressed("throttle_up"):
		throttle = clampf(throttle + 0.5 * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"):
		throttle = clampf(throttle - 0.5 * delta, 0.0, 1.0)

	# Set target control positions (keyboard sets target, not direct input)
	pitch_target = Input.get_axis("pitch_down", "pitch_up")
	roll_target = Input.get_axis("roll_left", "roll_right")
	yaw_target = Input.get_axis("yaw_left", "yaw_right")

func update_control_positions(delta: float) -> void:
	# Smoothly move actual control positions toward targets
	# This simulates the joystick moving gradually, not instantly
	pitch_input = move_toward(pitch_input, pitch_target, control_acceleration * delta)
	roll_input = move_toward(roll_input, roll_target, control_acceleration * delta)
	yaw_input = move_toward(yaw_input, yaw_target, control_acceleration * delta)

func calculate_flight_parameters() -> void:
	# Airspeed
	airspeed_mps = aircraft_velocity.length()
	airspeed_kts = airspeed_mps * MPS_TO_KTS

	# Altitude
	altitude_m = global_position.y
	altitude_ft = altitude_m * M_TO_FT

	# Vertical speed
	vertical_speed_mps = aircraft_velocity.y
	vertical_speed_fpm = vertical_speed_mps * MPS_TO_FPM

	# Get local velocity for AoA calculation
	var local_velocity = global_transform.basis.inverse() * aircraft_velocity

	# Angle of attack
	if local_velocity.z < -0.1:
		aoa_deg = rad_to_deg(atan2(-local_velocity.y, -local_velocity.z))
	else:
		aoa_deg = 0.0

	# Attitude from transform
	var euler = global_transform.basis.get_euler()
	pitch_deg = -rad_to_deg(euler.x)
	roll_deg = rad_to_deg(euler.z)
	heading_deg = -rad_to_deg(euler.y)
	if heading_deg < 0:
		heading_deg += 360.0

func apply_aerodynamics(delta: float) -> void:
	var speed = airspeed_mps
	if speed < 0.1:
		# Apply gravity when nearly stationary
		aircraft_velocity.y -= GRAVITY * delta
		return

	# Air density (decreases with altitude)
	var rho = 1.225 * pow(1.0 - 0.0000226 * altitude_m, 4.256)
	rho = maxf(rho, 0.3)

	# Dynamic pressure
	var q = 0.5 * rho * speed * speed

	# Lift coefficient
	var cl = lift_coefficient_base + (aoa_deg * lift_coefficient_per_aoa)

	# Stall modeling - gradual lift reduction
	if absf(aoa_deg) > critical_aoa_deg:
		var excess_aoa = absf(aoa_deg) - critical_aoa_deg
		var stall_factor = 1.0 - (excess_aoa * 0.08)
		cl *= clampf(stall_factor, 0.2, 1.0)

	cl = clampf(cl, -0.5, 1.6)

	# Lift force
	var lift_magnitude = cl * q * wing_area_m2
	var lift_direction = global_transform.basis.y
	var lift = lift_direction * lift_magnitude

	# Drag coefficient (parasite + induced)
	var aspect_ratio = (wing_span_m * wing_span_m) / wing_area_m2
	var oswald_efficiency = 0.8
	var cdi = (cl * cl) / (PI * aspect_ratio * oswald_efficiency)
	var cd_total = drag_coefficient + cdi
	var drag_magnitude = cd_total * q * wing_area_m2
	var drag = -aircraft_velocity.normalized() * drag_magnitude

	# Thrust (decreases slightly with airspeed)
	var thrust_factor = 1.0 - (airspeed_kts / 200.0) * 0.3
	thrust_factor = clampf(thrust_factor, 0.5, 1.0)
	var thrust_direction = -global_transform.basis.z
	var thrust = thrust_direction * thrust_max_n * throttle * thrust_factor

	# Weight
	var weight = Vector3.DOWN * mass_kg * GRAVITY

	# Sum forces and convert to acceleration
	var total_force = lift + drag + thrust + weight
	var acceleration = total_force / mass_kg

	# Calculate G-load
	g_load = lift.length() / (mass_kg * GRAVITY)

	# Update velocity
	aircraft_velocity += acceleration * delta

func apply_controls(delta: float) -> void:
	var speed = airspeed_kts

	# Control effectiveness scales with airspeed (reduced at low speed)
	var effectiveness = clampf(speed / 60.0, 0.1, 1.0)

	# Reduce effectiveness above Va (maneuvering speed)
	if speed > va_kts:
		effectiveness *= clampf(1.0 - (speed - va_kts) / 50.0, 0.5, 1.0)

	# Apply rotations based on actual control positions (not targets)
	var pitch_change = pitch_input * pitch_rate * effectiveness * delta
	var roll_change = -roll_input * roll_rate * effectiveness * delta
	var yaw_change = -yaw_input * yaw_rate * effectiveness * delta

	# Rotate the aircraft
	rotate_object_local(Vector3.RIGHT, deg_to_rad(pitch_change))
	rotate_object_local(Vector3.FORWARD, deg_to_rad(roll_change))
	rotate_object_local(Vector3.UP, deg_to_rad(yaw_change))

	# Nose drop tendency when stalled
	if absf(aoa_deg) > stall_aoa_deg:
		rotate_object_local(Vector3.RIGHT, deg_to_rad(15.0 * delta))

func apply_movement(_delta: float) -> void:
	velocity = aircraft_velocity
	move_and_slide()
	aircraft_velocity = velocity

	if is_on_floor():
		aircraft_velocity.y = maxf(aircraft_velocity.y, 0)

func update_position_coords(delta: float) -> void:
	var lat_rad = deg_to_rad(latitude)
	var meters_per_deg_lat = 111000.0
	var meters_per_deg_lon = 111000.0 * cos(lat_rad)

	latitude += (aircraft_velocity.z * delta) / meters_per_deg_lat
	longitude += (aircraft_velocity.x * delta) / meters_per_deg_lon

func check_overspeed() -> void:
	# Visual/audio warning could be added here
	if airspeed_kts > vne_kts:
		# Aircraft is overspeed - in real sim would cause damage
		# For now just clamp the speed slightly
		var excess = airspeed_kts - vne_kts
		if excess > 10:
			aircraft_velocity *= 0.99  # Gradual speed reduction

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		set_view_mode(not is_cockpit_view)
