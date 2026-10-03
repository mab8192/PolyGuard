class_name SettingsPopup extends CanvasLayer

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var reset_button: Button = %ResetButton
@onready var dev_cheats_button: Button = %DevCheatsButton
@onready var credits_button: Button = %CreditsButton
@onready var close_button: Button = %CloseButton
@onready var premium_status_label: Label = %PremiumStatusLabel
@onready var remove_ads_button: Button = %RemoveAdsButton
@onready var restore_purchases_button: Button = %RestorePurchasesButton
var _privacy_button: Button = null
var _debug_premium_button: Button = null

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
	_ensure_debug_premium_button()
	remove_ads_button.pressed.connect(_on_remove_ads_pressed)
	restore_purchases_button.pressed.connect(_on_restore_purchases_pressed)
	PurchaseManager.entitlement_changed.connect(func(_is_premium: bool) -> void: _refresh_premium())
	PurchaseManager.store_state_changed.connect(_refresh_premium)
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
	_refresh_premium()
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


func _ensure_debug_premium_button() -> void:
	if _debug_premium_button or not PurchaseManager.can_debug_toggle():
		return
	_debug_premium_button = Button.new()
	_debug_premium_button.custom_minimum_size = Vector2(0, 80)
	_debug_premium_button.focus_mode = Control.FOCUS_NONE
	_debug_premium_button.theme_type_variation = &"SecondaryButton"
	_debug_premium_button.pressed.connect(PurchaseManager.debug_toggle_premium)
	var parent := remove_ads_button.get_parent()
	parent.add_child(_debug_premium_button)


func _refresh_premium() -> void:
	var owned := PurchaseManager.is_premium
	premium_status_label.visible = owned or not PurchaseManager.status_message.is_empty()
	if owned:
		premium_status_label.text = "PREMIUM — ADS REMOVED"
	else:
		premium_status_label.text = PurchaseManager.status_message
	remove_ads_button.visible = not owned
	restore_purchases_button.visible = not owned and PurchaseManager.is_store_supported()
	remove_ads_button.disabled = PurchaseManager.purchase_busy
	restore_purchases_button.disabled = PurchaseManager.purchase_busy
	if PurchaseManager.purchase_busy:
		remove_ads_button.text = "PLEASE WAIT..."
	elif PurchaseManager.price_text.is_empty():
		remove_ads_button.text = "REMOVE ADS"
	else:
		remove_ads_button.text = "REMOVE ADS — %s" % PurchaseManager.price_text
	if _debug_premium_button:
		_debug_premium_button.text = "DEBUG: PREMIUM ON" if owned else "DEBUG: PREMIUM OFF"


func _on_remove_ads_pressed() -> void:
	PurchaseManager.purchase_remove_ads()
	_refresh_premium()


func _on_restore_purchases_pressed() -> void:
	PurchaseManager.restore_purchases()
	_refresh_premium()


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
