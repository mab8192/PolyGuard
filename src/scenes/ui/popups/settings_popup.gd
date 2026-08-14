class_name SettingsPopup extends CanvasLayer

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var reset_button: Button = %ResetButton
@onready var close_button: Button = %CloseButton

func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	reset_button.pressed.connect(_on_reset_pressed)
	_setup_sliders()

func open() -> void:
	_setup_sliders()
	reset_button.text = "RESET SAVE DATA"
	show()

func close() -> void:
	hide()

func _setup_sliders() -> void:
	master_slider.value = SettingsManager.get_bus_volume("Master", 1.0)
	master_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("Master", val)
	)
	
	music_slider.value = SettingsManager.get_bus_volume("Music", 1.0)
	music_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("Music", val)
	)
	
	sfx_slider.value = SettingsManager.get_bus_volume("SFX", 1.0)
	sfx_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("SFX", val)
	)

func _on_reset_pressed() -> void:
	SaveManager._init_defaults()
	SaveManager.save_to_disk()
	SignalBus.credits_changed.emit(0)
	SignalBus.stage_unlocked.emit("stage_01")
	SignalBus.tower_unlocked.emit("archer_tower")
	reset_button.text = "DATA RESET COMPLETE"
