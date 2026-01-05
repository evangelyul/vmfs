extends CanvasLayer

## Pause Menu - Overlay during flight

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work while game is paused

	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	resume_button.grab_focus()

func _on_resume_pressed() -> void:
	GameManager.resume_game()

func _on_restart_pressed() -> void:
	queue_free()
	GameManager.restart_flight()

func _on_settings_pressed() -> void:
	GameManager.show_settings(true)

func _on_quit_pressed() -> void:
	queue_free()
	GameManager.quit_to_menu()
