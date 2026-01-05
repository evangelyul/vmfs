# Flight Simulator Development Plan

## Phase 1: Core Flight (Current)
- [x] Project setup with godot-mcp
- [ ] Basic aircraft with flight physics
- [ ] Keyboard controls working
- [ ] Simple HUD (speed, alt, heading)
- [ ] UDP output to FDR tool
- [ ] Ground plane

**Done when:** Can take off, fly around, land without crashing to desktop

---

## Phase 2: Flight Model Refinement
- [ ] Tune lift/drag curves for realistic feel
- [ ] Add flaps (increase lift + drag)
- [ ] Add landing gear (drag when down)
- [ ] Ground effect (extra lift below 50ft)
- [ ] Improved stall behavior (wing drop, buffet)
- [ ] Propeller torque effect

**Done when:** Flight feels believable, can practice takeoffs/landings

---

## Phase 3: Cockpit Instruments
- [ ] Airspeed indicator (gauge style)
- [ ] Altimeter (3-pointer or tape)
- [ ] Vertical speed indicator
- [ ] Attitude indicator (artificial horizon)
- [ ] Heading indicator / compass
- [ ] Turn coordinator
- [ ] Engine instruments (RPM, manifold pressure)

**Done when:** Can fly on instruments alone

---

## Phase 4: LGAT Environment
- [ ] SRTM terrain heightmap for Athens area
- [ ] LGAT runway 03L/21R placed from your coords
- [ ] Taxiways and apron areas
- [ ] Basic airport buildings (boxes)
- [ ] Coastline / water
- [ ] Saronic Gulf visible

**Done when:** Recognizable Athens/Hellenikon from the air

---

## Phase 5: Navigation
- [ ] Load waypoints from your ARINC database
- [ ] VOR/NDB positions from your Jeppesen data
- [ ] HSI instrument with course needle
- [ ] NAV radio tuning
- [ ] DME distance display
- [ ] Moving map (optional)

**Done when:** Can fly a SID/STAR using real LGAT procedures

---

## Phase 6: Integration with Your Tools
- [ ] Verify UDP works with VB.NET FDR capture
- [ ] Test strip chart analysis with sim data
- [ ] Export flight track to GeoJSON
- [ ] Overlay on OpenLayers map
- [ ] Compare sim track to chart procedures

**Done when:** Full loop - fly in Godot, analyze in VB.NET, view on map

---

## Phase 7: Polish
- [ ] Engine sound (pitch varies with RPM)
- [ ] Wind/airflow sound
- [ ] Better aircraft model (free asset or simple)
- [ ] Skybox with clouds
- [ ] Day/night cycle (optional)
- [ ] Joystick support refinement
- [ ] Settings menu (controls, graphics)

**Done when:** Presentable demo

---

## Phase 8: Advanced (Optional)
- [ ] Multiple aircraft types
- [ ] ILS approach with glideslope
- [ ] Autopilot (basic wing leveler + altitude hold)
- [ ] Failures (engine, instruments)
- [ ] Weather (wind, turbulence)
- [ ] AI traffic
- [ ] Other Greek airports

---

## Priority Order
1. Phase 1 - Get flying
2. Phase 2 - Make it feel right
3. Phase 4 - LGAT environment (your main interest)
4. Phase 5 - Navigation (connects to your chart work)
5. Phase 6 - Integration (the whole point)
6. Phase 3 - Instruments (as needed)
7. Phase 7-8 - When core is solid

---

## Time Estimates (Rough)
| Phase | Estimate |
|-------|----------|
| 1 | 1-2 days |
| 2 | 2-3 days |
| 3 | 3-5 days |
| 4 | 1 week |
| 5 | 1 week |
| 6 | 2-3 days |
| 7 | 1 week |
| 8 | Ongoing |

Total to flyable LGAT with nav: ~4-6 weeks casual pace
