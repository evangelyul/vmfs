extends CanvasLayer

## Settings Menu - Controls, Graphics, Audio configuration

@onready var tab_container: TabContainer = $Panel/VBoxContainer/TabContainer

# Controls tab
@onready var sensitivity_slider: HSlider = $Panel/VBoxContainer/TabContainer/Controls/SensitivityContainer/SensitivitySlider
@onready var sensitivity_value: Label = $Panel/VBoxContainer/TabContainer/Controls/SensitivityContainer/SensitivityValue
@onready var invert_pitch_check: CheckButton = $Panel/VBoxContainer/TabContainer/Controls/InvertPitchCheck
@onready var controller_info: Label = $Panel/VBoxContainer/TabContainer/Controls/ControllerInfo

# Graphics tab
@onready var quality_option: OptionButton = $Panel/VBoxContainer/TabContainer/Graphics/QualityContainer/QualityOption
@onready var vsync_check: CheckButton = $Panel/VBoxContainer/TabContainer/Graphics/VSyncCheck
@onready var fullscreen_check: CheckButton = $Panel/VBoxContainer/TabContainer/Graphics/FullscreenCheck

# Audio tab
@onready var master_slider: HSlider = $Panel/VBoxContainer/TabContainer/Audio/MasterContainer/MasterSlider
@onready var master_value: Label = $Panel/VBoxContainer/TabContainer/Audio/MasterContainer/MasterValue
@onready var engine_slider: HSlider = $Panel/VBoxContainer/TabContainer/Audio/EngineContainer/EngineSlider
@onready var engine_value: Label = $Panel/VBoxContainer/TabContainer/Audio/EngineContainer/EngineValue

@onready var apply_button: Button = $Panel/VBoxContainer/ButtonContainer/ApplyButton
@onready var back_button: Button = $Panel/VBoxContainer/ButtonContainer/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_setup_quality_options()
	_load_current_settings()
	_update_controller_info()

	# Connect signals
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	master_slider.value_changed.connect(_on_master_changed)
	engine_slider.value_changed.connect(_on_engine_changed)

	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)

	back_button.grab_focus()

func _setup_quality_options() -> void:
	quality_option.clear()
	quality_option.add_item("Low", 0)
	quality_option.add_item("Medium", 1)
	quality_option.add_item("High", 2)
	quality_option.add_item("Ultra", 3)

func _load_current_settings() -> void:
	var settings = GameManager.settings

	# Controls
	sensitivity_slider.value = settings["controls"]["sensitivity"]
	sensitivity_value.text = "%.1f" % settings["controls"]["sensitivity"]
	invert_pitch_check.button_pressed = settings["controls"]["invert_pitch"]

	# Graphics
	quality_option.selected = settings["graphics"]["quality_preset"]
	vsync_check.button_pressed = settings["graphics"]["vsync"]
	fullscreen_check.button_pressed = settings["graphics"]["fullscreen"]

	# Audio
	master_slider.value = settings["audio"]["master_volume"]
	master_value.text = "%d%%" % int(settings["audio"]["master_volume"] * 100)
	engine_slider.value = settings["audio"]["engine_volume"]
	engine_value.text = "%d%%" % int(settings["audio"]["engine_volume"] * 100)

func _update_controller_info() -> void:
	var input_manager = get_node_or_null("/root/InputManager")
	if input_manager:
		if input_manager.has_controller():
			controller_info.text = "Controller: %s" % input_manager.get_controller_name()
		else:
			controller_info.text = "No controller detected"
	else:
		controller_info.text = "Input manager not available"

func _on_sensitivity_changed(value: float) -> void:
	sensitivity_value.text = "%.1f" % value

func _on_master_changed(value: float) -> void:
	master_value.text = "%d%%" % int(value * 100)

func _on_engine_changed(value: float) -> void:
	engine_value.text = "%d%%" % int(value * 100)

func _on_apply_pressed() -> void:
	var settings = GameManager.settings

	# Controls
	settings["controls"]["sensitivity"] = sensitivity_slider.value
	settings["controls"]["invert_pitch"] = invert_pitch_check.button_pressed

	# Graphics
	settings["graphics"]["quality_preset"] = quality_option.selected
	settings["graphics"]["vsync"] = vsync_check.button_pressed
	settings["graphics"]["fullscreen"] = fullscreen_check.button_pressed

	# Audio
	settings["audio"]["master_volume"] = master_slider.value
	settings["audio"]["engine_volume"] = engine_slider.value

	GameManager.save_settings()
	GameManager.apply_graphics_settings()
	GameManager.apply_audio_settings()

	print("Settings applied")

func _on_back_pressed() -> void:
	GameManager.close_settings()
	queue_free()
