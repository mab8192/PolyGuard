class_name NavBar extends Panel

enum Tab { CAMPAIGN, INVENTORY, CODEX, SETTINGS }

signal tab_select(tab: Tab)

@onready var campaign_button: TextureButton = %CampaignButton
@onready var campaign_label: Label = %CampaignLabel
@onready var inventory_button: TextureButton = %InventoryButton
@onready var inventory_label: Label = %InventoryLabel
@onready var codex_button: TextureButton = %CodexButton
@onready var codex_label: Label = %CodexLabel
@onready var settings_button: TextureButton = %SettingsButton
@onready var settings_label: Label = %SettingsLabel

@onready var _selected: BaseButton = campaign_button

func _ready() -> void:
	campaign_button.pressed.connect(func (): _on_select(campaign_button))
	inventory_button.pressed.connect(func (): _on_select(inventory_button))
	codex_button.pressed.connect(func (): _on_select(codex_button))
	settings_button.pressed.connect(func (): _on_select(settings_button))

func _on_select(btn: BaseButton) -> void:
	if btn == _selected: return
	
	var tab: Tab = Tab.CAMPAIGN
	
	match btn:
		campaign_button:
			tab = Tab.CAMPAIGN
		inventory_button:
			tab = Tab.INVENTORY
		codex_button:
			tab = Tab.CODEX
		settings_button:
			tab = Tab.SETTINGS
	
	_selected = btn
	_update_style()

	tab_select.emit(tab)

func _update_style() -> void:
	match _selected:
		campaign_button:
			campaign_label.show()
			inventory_label.hide()
			codex_label.hide()
			settings_label.hide()
		inventory_button:
			campaign_label.hide()
			inventory_label.show()
			codex_label.hide()
			settings_label.hide()
		codex_button:
			campaign_label.hide()
			inventory_label.hide()
			codex_label.show()
			settings_label.hide()
		settings_button:
			campaign_label.hide()
			inventory_label.hide()
			codex_label.hide()
			settings_label.show()
