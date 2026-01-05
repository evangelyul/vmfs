# LGAT Flight Simulator - Project Requirements

## Target
Godot 4.3+ flight simulator with semi-realistic physics

## Folder Structure
```
lgat_flight_sim/
├── project.godot
├── scenes/
│   ├── main.tscn (world + aircraft + camera)
│   ├── aircraft.tscn (aircraft scene)
│   ├── hud.tscn (2D instrument overlay)
│   └── terrain.tscn (ground plane or heightmap)
├── scripts/
│   ├── aircraft.gd (flight model)
│   ├── hud.gd (instrument display)
│   ├── fdr_output.gd (UDP to external FDR tool)
│   └── camera_controller.gd (chase/cockpit toggle)
├── assets/
│   └── (models, textures if any)
└── addons/
    └── (optional)
```

## Core Features Required
1. Flyable aircraft with lift/drag/thrust/weight physics
2. Keyboard input (WASD + QE + Shift/Ctrl)
3. Chase camera
4. Basic HUD: airspeed, altitude, heading, throttle
5. UDP output on port 49003 (X-Plane DATA format)
6. Simple ground plane to start

## HUD Elements (2D Overlay)
- Airspeed (kts)
- Altitude (ft)
- Vertical speed (fpm)
- Heading (deg)
- Throttle (%)
- Pitch/Roll indicators

## UDP Packet Format
Header: "DATA" + 0x00 (5 bytes)
Then 36-byte groups: int32 index + 8x float32 values

Group 3 (Speeds): Vind_kias, Vind_keas, Vtrue_ktas, Vtrue_ktgs, 0, 0, 0, 0
Group 4 (Rates): Vmach, 0, Vvi_fpm, 0, 0, Gload_norm, Gload_axil, Gload_side
Group 17 (Attitude): pitch_deg, roll_deg, hding_true, hding_mag, 0, 0, 0, 0
Group 20 (Position): lat_deg, lon_deg, alt_msl_ft, alt_agl_ft, on_runway, 0, 0, 0

## Starting Position
Lat: 37.9487 (near Athens LGAT)
Lon: 23.9447
Alt: 300m (runway elevation)
Heading: 217 (runway 21)

## Do NOT Include
- Complex terrain (simple plane is fine)
- 3D cockpit (HUD overlay only)
- Multiplayer
- Weather systems
