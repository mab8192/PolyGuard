extends Control

@onready var play_button: Button = %PlayButton
@onready var armory_button: Button = %ArmoryButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

@onready var settings_popup: PanelContainer = %SettingsPopup
@onready var bgm_slider: HSlider = %BGMSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var close_settings_button: Button = %CloseSettingsButton

@onready var armory_popup: PanelContainer = %ArmoryPopup
@onready var close_armory_button: Button = %CloseArmoryButton

func _ready() -> void:
	if AudioManager and AudioManager.music_menu:
		AudioManager.play_music(AudioManager.music_menu)
		
	play_button.pressed.connect(_on_play_pressed)
	armory_button.pressed.connect(_on_armory_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	close_settings_button.pressed.connect(func(): settings_popup.hide())
	close_armory_button.pressed.connect(func(): armory_popup.hide())
	
	settings_popup.hide()
	armory_popup.hide()
	
	_setup_audio_sliders()

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

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/ui/stage_select.tscn")

func _on_armory_pressed() -> void:
	armory_popup.show()

func _on_settings_pressed() -> void:
	settings_popup.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
