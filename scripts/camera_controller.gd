extends Node3D

## Camera Controller - Chase and cockpit camera toggle

@export var aircraft_path: NodePath
@export var chase_distance: float = 9.0  # 30 ft behind tail
@export var chase_height: float = 2.5    # Slightly above
@export var cockpit_offset: Vector3 = Vector3(0, 0.8, 2.0)  # Pilot eye position (adjust as needed)
@export var smoothing: float = 8.0

var aircraft: Node3D = null
var camera: Camera3D = null
var is_cockpit_view: bool = false

func _ready() -> void:
	# Get or create camera
	camera = get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
		camera.current = true

	camera.fov = 70.0

	# Find aircraft
	await get_tree().process_frame
	if aircraft_path:
		aircraft = get_node_or_null(aircraft_path)
	if not aircraft:
		aircraft = get_tree().get_first_node_in_group("aircraft")
	if not aircraft:
		aircraft = get_node_or_null("../Aircraft")

	# Connect to aircraft view_changed signal
	if aircraft and aircraft.has_signal("view_changed"):
		aircraft.connect("view_changed", _on_view_changed)

func _on_view_changed(cockpit: bool) -> void:
	is_cockpit_view = cockpit
	print("Camera: %s view" % ("Cockpit" if cockpit else "External"))

func _process(delta: float) -> void:
	if not aircraft or not camera:
		return

	if is_cockpit_view:
		update_cockpit_camera(delta)
	else:
		update_chase_camera(delta)

func update_chase_camera(delta: float) -> void:
	# Get aircraft position and orientation
	var target_pos = aircraft.global_position

	# Godot standard: forward is -Z, so backward (behind tail) is +Z
	var aircraft_back = aircraft.global_transform.basis.z
	var aircraft_up = Vector3.UP

	# Position camera behind and above the aircraft
	var desired_pos = target_pos + aircraft_back * chase_distance + aircraft_up * chase_height

	# Smooth camera movement
	camera.global_position = camera.global_position.lerp(desired_pos, smoothing * delta)

	# Look at aircraft center
	camera.look_at(target_pos, Vector3.UP)

func update_cockpit_camera(_delta: float) -> void:
	# Position at pilot's eye level inside cockpit
	# Offset is in aircraft local space
	var cockpit_pos = aircraft.global_position + aircraft.global_transform.basis * cockpit_offset
	camera.global_position = cockpit_pos

	# Match aircraft rotation exactly for cockpit view
	camera.global_transform.basis = aircraft.global_transform.basis

func _input(_event: InputEvent) -> void:
	# Camera toggle is handled by aircraft.gd
	pass
