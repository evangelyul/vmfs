extends Node

## Game Manager - Handles game state, scene transitions, and settings persistence
## Autoload singleton

signal game_paused
signal game_resumed
signal game_state_changed(new_state: GameState)

enum GameState { MAIN_MENU, FLYING, PAUSED, SETTINGS }

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU
var flight_scene_path: String = "res://scenes/main.tscn"
var main_menu_path: String = "res://ui/main_menu.tscn"

# Settings storage
var settings: Dictionary = {
	"graphics": {
		"quality_preset": 1,  # 0=Low, 1=Medium, 2=High, 3=Ultra
		"vsync": true,
		"fullscreen": false
	},
	"audio": {
		"master_volume": 1.0,
		"engine_volume": 0.8,
		"ui_volume": 0.5
	},
	"controls": {
		"sensitivity": 1.0,
		"invert_pitch": false
	}
}

func _ready() -> void:
	load_settings()
	apply_graphics_settings()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Continue during pause

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		match current_state:
			GameState.FLYING:
				pause_game()
			GameState.PAUSED:
				resume_game()
			GameState.SETTINGS:
				# Return to previous menu
				if previous_state == GameState.PAUSED:
					_remove_current_overlay()
					set_state(GameState.PAUSED)
				else:
					_remove_current_overlay()
					set_state(GameState.MAIN_MENU)

func set_state(new_state: GameState) -> void:
	previous_state = current_state
	current_state = new_state
	emit_signal("game_state_changed", new_state)

func start_flight() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(flight_scene_path)
	set_state(GameState.FLYING)

func show_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_path)
	set_state(GameState.MAIN_MENU)

func pause_game() -> void:
	get_tree().paused = true
	set_state(GameState.PAUSED)
	# Instantiate pause menu overlay
	var pause_scene = load("res://ui/pause_menu.tscn")
	var pause_menu = pause_scene.instantiate()
	pause_menu.name = "PauseMenu"
	get_tree().current_scene.add_child(pause_menu)
	emit_signal("game_paused")

func resume_game() -> void:
	get_tree().paused = false
	set_state(GameState.FLYING)
	_remove_pause_menu()
	emit_signal("game_resumed")

func restart_flight() -> void:
	_remove_pause_menu()
	get_tree().paused = false
	get_tree().reload_current_scene()
	set_state(GameState.FLYING)

func show_settings(from_pause: bool = false) -> void:
	previous_state = current_state
	set_state(GameState.SETTINGS)
	var settings_scene = load("res://ui/settings_menu.tscn")
	var settings_menu = settings_scene.instantiate()
	settings_menu.name = "SettingsMenu"
	settings_menu.set_meta("from_pause", from_pause)
	get_tree().current_scene.add_child(settings_menu)

func close_settings() -> void:
	_remove_settings_menu()
	if previous_state == GameState.PAUSED:
		set_state(GameState.PAUSED)
	else:
		set_state(GameState.MAIN_MENU)

func quit_to_menu() -> void:
	_remove_pause_menu()
	get_tree().paused = false
	show_main_menu()

func quit_game() -> void:
	save_settings()
	get_tree().quit()

func _remove_pause_menu() -> void:
	var pause_menu = get_tree().current_scene.get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.queue_free()

func _remove_settings_menu() -> void:
	var settings_menu = get_tree().current_scene.get_node_or_null("SettingsMenu")
	if settings_menu:
		settings_menu.queue_free()

func _remove_current_overlay() -> void:
	_remove_pause_menu()
	_remove_settings_menu()

# Settings management
func save_settings() -> void:
	var config = ConfigFile.new()
	for category in settings:
		for key in settings[category]:
			config.set_value(category, key, settings[category][key])
	config.save("user://settings.cfg")
	print("Settings saved")

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for category in settings:
			for key in settings[category]:
				if config.has_section_key(category, key):
					settings[category][key] = config.get_value(category, key)
		print("Settings loaded")

func apply_graphics_settings() -> void:
	var gfx = settings["graphics"]

	# VSync
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if gfx["vsync"] else DisplayServer.VSYNC_DISABLED
	)

	# Fullscreen
	if gfx["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func apply_audio_settings() -> void:
	var audio = settings["audio"]
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(audio["master_volume"]))
