class_name PauseMenu extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var main_menu_button: Button = %MainMenuButton

@onready var bgm_slider: HSlider = %BGMSlider
@onready var sfx_slider: HSlider = %SFXSlider

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()

	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	_setup_audio_sliders()

func open() -> void:
	get_tree().paused = true
	show()

func close() -> void:
	get_tree().paused = false
	hide()

func _setup_audio_sliders() -> void:
	bgm_slider.value = SettingsManager.get_bus_volume("Music", 1.0)
	bgm_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("Music", val)
	)

	sfx_slider.value = SettingsManager.get_bus_volume("SFX", 1.0)
	sfx_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("SFX", val)
	)

func _on_resume_pressed() -> void:
	close()

func _on_restart_pressed() -> void:
	close()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	close()
	GameManager.load_view(GameManager.View.MAIN_MENU)
