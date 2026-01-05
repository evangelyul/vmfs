extends CanvasLayer

## HUD - Instrument Display Overlay

@onready var airspeed_label: Label = $FlightData/AirspeedLabel
@onready var altitude_label: Label = $FlightData/AltitudeLabel
@onready var vsi_label: Label = $FlightData/VSILabel
@onready var heading_label: Label = $FlightData/HeadingLabel
@onready var throttle_label: Label = $FlightData/ThrottleLabel
@onready var pitch_label: Label = $FlightData/PitchLabel
@onready var roll_label: Label = $FlightData/RollLabel
@onready var ground_state_label: Label = $FlightData/GroundStateLabel
@onready var controller_label: Label = $FlightData/ControllerLabel

var aircraft: Node = null

func _ready() -> void:
	# Find aircraft in the scene
	await get_tree().process_frame
	aircraft = get_tree().get_first_node_in_group("aircraft")
	if not aircraft:
		aircraft = get_node_or_null("../Aircraft")

func _process(_delta: float) -> void:
	if not aircraft:
		return

	# Update text displays
	airspeed_label.text = "IAS: %d kts" % int(aircraft.airspeed_kts)
	altitude_label.text = "ALT: %d ft" % int(aircraft.altitude_ft)

	var vsi_sign = "+" if aircraft.vertical_speed_fpm >= 0 else ""
	vsi_label.text = "VS: %s%d fpm" % [vsi_sign, int(aircraft.vertical_speed_fpm)]

	heading_label.text = "HDG: %03d°" % int(aircraft.heading_deg)
	throttle_label.text = "THR: %d%%" % int(aircraft.throttle * 100)
	pitch_label.text = "PITCH: %+.1f°" % aircraft.pitch_deg
	roll_label.text = "ROLL: %+.1f°" % aircraft.roll_deg

	# Ground state display
	if aircraft.has_method("get_ground_state_name"):
		ground_state_label.text = "STATE: %s" % aircraft.get_ground_state_name()

	# Controller status
	var input_manager = get_node_or_null("/root/InputManager")
	if input_manager and input_manager.has_controller():
		controller_label.text = "CTRL: Joystick"
	else:
		controller_label.text = "CTRL: Keyboard"
