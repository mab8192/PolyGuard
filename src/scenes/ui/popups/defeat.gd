extends CanvasLayer

@onready var title_label: Label = %TitleLabel
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
		var score = GameManager.current_stage.score
		var stage_id = Registry.get_stage_id(GameManager.current_stage.data)
		
		if GameManager.is_endless_mode:
			var waves_cleared: int = maxi(0, wave - 1)
			var endless_res: Dictionary = SaveManager.record_endless_run(stage_id, waves_cleared, score)
			
			if title_label:
				title_label.text = "ENDLESS CONCLUDED"
			
			var highest_wave: int = endless_res.get("highest_wave", waves_cleared)
			var is_new: bool = endless_res.get("is_new_wave_record", false)
			var earned: int = endless_res.get("total_reward", 0)
			
			var record_str: String = "NEW PERSONAL BEST!" if is_new else ("Personal Best: Wave %d" % highest_wave)
			desc_label.text = "Waves Cleared: %d\n%s\nFinal Score: %d\nCredits Earned: +%d" % [
				waves_cleared, record_str, score, earned
			]
			if retry_button:
				retry_button.text = "RETRY ENDLESS"
		else:
			if title_label:
				title_label.text = "DEFEAT"
			var total_waves = GameManager.current_stage.data.get_waves().size()
			desc_label.text = "Overwhelmed on Wave %d of %d\nScore: %d" % [wave, total_waves, score]
			if retry_button:
				retry_button.text = "RETRY"
	show()
	
	get_tree().paused = true

func _on_retry_pressed() -> void:
	Engine.time_scale = 1.0
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
