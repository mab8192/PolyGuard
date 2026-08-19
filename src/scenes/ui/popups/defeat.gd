extends CanvasLayer

@onready var desc_label: Label = %DescLabel
@onready var retry_button: Button = %RetryButton
@onready var loadout_button: Button = %LoadoutButton
@onready var inventory_button: Button = %InventoryButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	hide()
	SignalBus.stage_failed.connect(_on_stage_failed)

	retry_button.pressed.connect(_on_retry_pressed)
	loadout_button.pressed.connect(_on_loadout_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_stage_failed() -> void:
	if GameManager.current_stage:
		var wave = GameManager.current_stage.wave
		var total_waves = GameManager.current_stage.data.get_waves().size()
		var score = GameManager.current_stage.score
		desc_label.text = "Overwhelmed on Wave %d of %d\nScore: %d" % [wave, total_waves, score]
	show()
	
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_loadout_pressed() -> void:
	get_tree().paused = false
	GameManager.load_view(GameManager.View.LOADOUT)

func _on_inventory_pressed() -> void:
	get_tree().paused = false
	GameManager.target_main_menu_tab = 1 # NavBar.Tab.INVENTORY
	GameManager.load_view(GameManager.View.MAIN_MENU)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.load_view(GameManager.View.MAIN_MENU)
