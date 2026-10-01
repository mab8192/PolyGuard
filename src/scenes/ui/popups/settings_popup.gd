class_name SettingsPopup extends CanvasLayer

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var reset_button: Button = %ResetButton
@onready var dev_cheats_button: Button = %DevCheatsButton
@onready var credits_button: Button = %CreditsButton
@onready var close_button: Button = %CloseButton
var _privacy_button: Button = null

const DEV_CHEAT_MENU_SCENE = preload("res://src/scenes/ui/popups/dev_cheat_menu.tscn")
const CREDITS_POPUP_SCENE = preload("res://src/scenes/ui/popups/credits_popup.tscn")
var _cheat_menu: DevCheatMenu = null
var _credits_popup: CreditsPopup = null
var _reset_armed: bool = false

func _ready() -> void:
	hide()
	add_to_group(GameManager.BACK_CLOSABLE_GROUP)
	close_button.pressed.connect(close)
	reset_button.pressed.connect(_on_reset_pressed)
	if dev_cheats_button:
		dev_cheats_button.visible = OS.is_debug_build()
		dev_cheats_button.pressed.connect(_on_dev_cheats_pressed)
	if credits_button:
		credits_button.pressed.connect(_on_credits_pressed)
	_ensure_privacy_button()
	_connect_slider_signals()
	_update_slider_values()

func _on_dev_cheats_pressed() -> void:
	if is_instance_valid(DevCheatMenu.instance):
		DevCheatMenu.instance.open()
	elif is_instance_valid(GameManager.dev_cheat_menu):
		GameManager.dev_cheat_menu.open()
	else:
		if not _cheat_menu:
			_cheat_menu = DEV_CHEAT_MENU_SCENE.instantiate() as DevCheatMenu
			add_child(_cheat_menu)
		_cheat_menu.open()

func _on_credits_pressed() -> void:
	if not _credits_popup:
		_credits_popup = CREDITS_POPUP_SCENE.instantiate() as CreditsPopup
		add_child(_credits_popup)
	_credits_popup.open()

func open() -> void:
	_update_slider_values()
	_reset_armed = false
	reset_button.text = "RESET SAVE DATA"
	_refresh_privacy_button()
	show()


func _ensure_privacy_button() -> void:
	if _privacy_button or credits_button == null:
		return
	_privacy_button = Button.new()
	_privacy_button.text = "AD PRIVACY OPTIONS"
	_privacy_button.custom_minimum_size = Vector2(0, 80)
	_privacy_button.focus_mode = Control.FOCUS_NONE
	_privacy_button.theme_type_variation = &"SecondaryButton"
	_privacy_button.visible = false
	_privacy_button.pressed.connect(_on_privacy_options_pressed)
	var parent := credits_button.get_parent()
	parent.add_child(_privacy_button)
	parent.move_child(_privacy_button, credits_button.get_index())


func _refresh_privacy_button() -> void:
	if _privacy_button == null:
		return
	var show_options := false
	if ConsentInformation._plugin != null:
		var status := UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
		show_options = status == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	_privacy_button.visible = show_options


func _on_privacy_options_pressed() -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_error: FormError) -> void:
		_refresh_privacy_button()
	)

func close() -> void:
	hide()

func _connect_slider_signals() -> void:
	master_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("Master", val)
	)
	
	music_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("Music", val)
	)
	
	sfx_slider.value_changed.connect(func(val: float):
		SettingsManager.set_bus_volume("SFX", val)
	)

func _update_slider_values() -> void:
	master_slider.set_value_no_signal(SettingsManager.get_bus_volume("Master", 1.0))
	music_slider.set_value_no_signal(SettingsManager.get_bus_volume("Music", 1.0))
	sfx_slider.set_value_no_signal(SettingsManager.get_bus_volume("SFX", 1.0))

func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = "TAP AGAIN TO ERASE ALL PROGRESS"
		return
	_reset_armed = false
	SaveManager._init_defaults()
	SaveManager.save_to_disk()
	SignalBus.credits_changed.emit(0)
	SignalBus.stage_unlocked.emit("stage_01")
	SignalBus.tower_unlocked.emit("archer_tower")
	reset_button.text = "DATA RESET COMPLETE"
