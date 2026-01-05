extends Node

## FDR Output - UDP packets to port 49003 in X-Plane DATA format

@export var target_port: int = 49003
@export var target_host: String = "127.0.0.1"
@export var send_rate_hz: float = 20.0

var udp: PacketPeerUDP
var aircraft: Node = null
var send_timer: float = 0.0

func _ready() -> void:
	udp = PacketPeerUDP.new()
	udp.set_dest_address(target_host, target_port)

	# Find aircraft
	await get_tree().process_frame
	aircraft = get_tree().get_first_node_in_group("aircraft")
	if not aircraft:
		aircraft = get_node_or_null("../Aircraft")

	print("FDR Output initialized - sending to %s:%d" % [target_host, target_port])

func _process(delta: float) -> void:
	if not aircraft:
		return

	send_timer += delta
	if send_timer >= 1.0 / send_rate_hz:
		send_timer = 0.0
		send_data_packet()

func send_data_packet() -> void:
	var packet = PackedByteArray()

	# Header: "DATA" + null byte
	packet.append_array("DATA".to_ascii_buffer())
	packet.append(0x00)

	# Group 3: Speeds
	packet.append_array(build_data_group(3, [
		aircraft.airspeed_kts,  # Vind_kias
		aircraft.airspeed_kts,  # Vind_keas (same for now)
		aircraft.airspeed_kts * 1.0,  # Vtrue_ktas (simplified)
		aircraft.airspeed_kts,  # Vtrue_ktgs (ground speed)
		0.0, 0.0, 0.0, 0.0
	]))

	# Group 4: Mach/VVI/G-load
	var mach = aircraft.airspeed_kts / 660.0  # Rough approximation
	packet.append_array(build_data_group(4, [
		mach,
		0.0,
		aircraft.vertical_speed_fpm,
		0.0, 0.0,
		aircraft.g_load,  # G-load normal
		0.0,  # G-load axial
		0.0   # G-load side
	]))

	# Group 17: Attitude
	packet.append_array(build_data_group(17, [
		aircraft.pitch_deg,
		aircraft.roll_deg,
		aircraft.heading_deg,  # True heading
		aircraft.heading_deg,  # Mag heading (same for now)
		0.0, 0.0, 0.0, 0.0
	]))

	# Group 20: Position
	var on_runway = 1.0 if aircraft.altitude_m < 10.0 else 0.0
	packet.append_array(build_data_group(20, [
		aircraft.latitude,
		aircraft.longitude,
		aircraft.altitude_ft,  # MSL
		aircraft.altitude_ft,  # AGL (same for flat terrain)
		on_runway,
		0.0, 0.0, 0.0
	]))

	udp.put_packet(packet)

func build_data_group(index: int, values: Array) -> PackedByteArray:
	var group = PackedByteArray()

	# Int32 index (little-endian)
	group.append(index & 0xFF)
	group.append((index >> 8) & 0xFF)
	group.append((index >> 16) & 0xFF)
	group.append((index >> 24) & 0xFF)

	# 8 float32 values (little-endian)
	for i in range(8):
		var val = values[i] if i < values.size() else 0.0
		var bytes = PackedFloat32Array([val]).to_byte_array()
		group.append_array(bytes)

	return group

func _exit_tree() -> void:
	if udp:
		udp.close()
