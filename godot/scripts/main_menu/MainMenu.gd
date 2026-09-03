extends Control

@onready var play_button: Button = $PlayButton
@onready var options_button: Button = $OptionsButton
@onready var quit_button: Button = $QuitButton
@onready var options_panel: Control = $OptionsPanel
@onready var fullscreen_check: CheckBox = $OptionsPanel/VBox/FullscreenCheck
@onready var sensitivity_slider: HSlider = $OptionsPanel/VBox/SensitivitySlider
@onready var volume_slider: HSlider = $OptionsPanel/VBox/VolumeSlider
@onready var back_button: Button = $OptionsPanel/VBox/BackButton

func _ready() -> void:
	play_button.pressed.connect(_on_play)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)
	back_button.pressed.connect(_on_back)
	fullscreen_check.toggled.connect(_on_fullscreen)
	sensitivity_slider.value_changed.connect(_on_sensitivity)
	volume_slider.value_changed.connect(_on_volume)
	options_panel.visible = false
	# Defaults
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	sensitivity_slider.min_value = 0.2
	sensitivity_slider.max_value = 2.0
	sensitivity_slider.step = 0.1
	sensitivity_slider.value = 1.0
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = 0.8
	_apply_volume(0.8)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/vertical_slice/VerticalSlice.tscn")

func _on_options() -> void:
	options_panel.visible = true

func _on_back() -> void:
	options_panel.visible = false

func _on_quit() -> void:
	get_tree().quit()

func _on_fullscreen(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_sensitivity(value: float) -> void:
	# Stored for future look/mouse scaling; vertical slice uses click selection
	ProjectSettings.set_setting("coldboot/mouse_sensitivity", value)

func _on_volume(value: float) -> void:
	_apply_volume(value)

func _apply_volume(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(clamp(value, 0.001, 1.0)))
