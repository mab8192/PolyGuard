class_name MainMenu extends Control

@onready var nav_bar: NavBar = %NavBar

@onready var campaign: Control = %Campaign
@onready var codex: Control = %Codex
@onready var inventory: Control = %Inventory
@onready var settings_button: TextureButton = %SettingsButton
@onready var settings_popup: SettingsPopup = %SettingsPopup
@onready var main_menu_credits_label: Label = %MainMenuCreditsLabel
@onready var tab_title_label: Label = %TabTitleLabel

func _ready() -> void:
	nav_bar.tab_select.connect(_on_tab_select)
	AudioManager.play_music(AudioManager.music_menu)
	settings_button.pressed.connect(_on_settings_select)
	
	SignalBus.credits_changed.connect(_on_credits_changed)
	_update_credits_display()
	
	if GameManager.target_main_menu_tab >= 0:
		var tab = GameManager.target_main_menu_tab as NavBar.Tab
		GameManager.target_main_menu_tab = -1
		nav_bar.select_tab(tab)
	else:
		_on_tab_select(NavBar.Tab.CAMPAIGN)

func _update_credits_display() -> void:
	if main_menu_credits_label:
		main_menu_credits_label.text = "%d CREDITS" % SaveManager.get_credits()

func _on_credits_changed(_credits: int) -> void:
	_update_credits_display()

func _on_tab_select(tab: NavBar.Tab) -> void:
	match tab:
		NavBar.Tab.CAMPAIGN:
			campaign.show()
			inventory.hide()
			codex.hide()
			if tab_title_label:
				tab_title_label.text = "CAMPAIGN"
		NavBar.Tab.INVENTORY:
			campaign.hide()
			inventory.show()
			codex.hide()
			if tab_title_label:
				tab_title_label.text = "TOWER ARSENAL"
		NavBar.Tab.CODEX:
			campaign.hide()
			inventory.hide()
			codex.show()
			if tab_title_label:
				tab_title_label.text = "ENEMY CODEX"

func _on_settings_select() -> void:
	if settings_popup:
		settings_popup.open()
