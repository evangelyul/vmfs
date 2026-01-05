extends Control

## Main Menu - Entry point for the game

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var aircraft_button: Button = $VBoxContainer/AircraftButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	aircraft_button.pressed.connect(_on_aircraft_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Aircraft selection is a stub for now
	aircraft_button.disabled = true
	aircraft_button.tooltip_text = "Coming Soon"

	# Set version info
	version_label.text = "v0.2.0 - Phase 2"

	start_button.grab_focus()

func _on_start_pressed() -> void:
	GameManager.start_flight()

func _on_aircraft_pressed() -> void:
	# Future: show aircraft selection
	pass

func _on_settings_pressed() -> void:
	GameManager.show_settings(false)

func _on_quit_pressed() -> void:
	GameManager.quit_game()
