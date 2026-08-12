class_name MainMenu extends Control

@onready var nav_bar: NavBar = %NavBar

@onready var campaign: Control = %Campaign
@onready var codex: Control = %Codex
@onready var inventory: Control = %Inventory

func _ready() -> void:
	nav_bar.tab_select.connect(_on_tab_select)
	AudioManager.play_music(AudioManager.music_menu)
	
func _on_tab_select(tab: NavBar.Tab) -> void:
	match tab:
		NavBar.Tab.CAMPAIGN:
			campaign.show()
			inventory.hide()
			codex.hide()
		NavBar.Tab.INVENTORY:
			campaign.hide()
			inventory.show()
			codex.hide()
		NavBar.Tab.CODEX:
			campaign.hide()
			inventory.hide()
			codex.show()
