# Flight Model Specification
# Reference file for Godot 4 flight simulator

## Aircraft Type: Light GA (Cessna 172 style)

## Physical Properties
mass_kg: 1000
wing_area_m2: 16.2
thrust_max_n: 12000
drag_coefficient: 0.027
lift_coefficient_base: 0.3
lift_coefficient_per_aoa: 0.1

## Control Authority (degrees/sec at cruise speed)
pitch_rate: 1.5
roll_rate: 2.5
yaw_rate: 0.8

## Limits
max_aoa_deg: 15
stall_aoa_deg: 18
vne_kts: 180
vs0_kts: 48

## Aerodynamics Formulas
# Air density: rho = 1.225 * (1 - 0.0000226 * alt_m)^4.256
# Dynamic pressure: q = 0.5 * rho * V^2
# Lift: L = Cl * q * S
# Drag: D = Cd * q * S + induced_drag
# Induced drag coefficient: Cdi = 0.05 * aoa^2 / 100

## Control Effectiveness
# Scales with airspeed: effectiveness = clamp(airspeed / 50.0, 0.1, 1.0)

## Stall Behavior
# Above max_aoa: gradual lift reduction
# Above stall_aoa: 70% lift loss, nose drop tendency

## Node Structure
Aircraft (CharacterBody3D)
├── CollisionShape3D (BoxShape3D, size 10x2x8)
├── MeshInstance3D (aircraft model or placeholder box)
├── Camera3D (offset 0, 2, 8 for chase view)
└── AudioStreamPlayer3D (engine loop)

## Input Actions Required
pitch_up, pitch_down (W/S or joystick Y)
roll_left, roll_right (A/D or joystick X)
yaw_left, yaw_right (Q/E)
throttle_up, throttle_down (Shift/Ctrl)

## UDP Output (Port 49003)
Format: X-Plane compatible DATA packets
Groups to send: 3 (speeds), 4 (mach/vvi/g), 17 (attitude), 20 (position)
