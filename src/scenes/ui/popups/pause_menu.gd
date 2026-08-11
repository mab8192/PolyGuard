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
	var music_bus_idx = AudioServer.get_bus_index("Music")
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")

	if music_bus_idx != -1:
		bgm_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))
		bgm_slider.value_changed.connect(func(val: float):
			AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(val))
		)

	if sfx_bus_idx != -1:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))
		sfx_slider.value_changed.connect(func(val: float):
			AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(val))
		)

func _on_resume_pressed() -> void:
	close()

func _on_restart_pressed() -> void:
	close()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	close()
	GameManager.load_view(GameManager.View.MAIN_MENU)
