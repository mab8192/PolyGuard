extends CanvasLayer

const STAR_EARNED_COLOR := Color(1.0, 0.82, 0.22, 1.0)
const STAR_UNEARNED_COLOR := Color(0.28, 0.32, 0.42, 0.45)


@onready var star_1: TextureRect = %Star1
@onready var star_2: TextureRect = %Star2
@onready var star_3: TextureRect = %Star3
@onready var stats_label: Label = %StatsLabel
@onready var reward_breakdown_label: Label = %RewardBreakdownLabel
@onready var next_unlock_label: Label = %NextUnlockLabel
@onready var next_stage_button: Button = %NextStageButton
@onready var continue_endless_button: Button = %ContinueEndlessButton
@onready var retry_button: Button = %RetryButton
@onready var inventory_button: Button = %InventoryButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	hide()
	SignalBus.stage_completed.connect(_on_stage_completed)

	next_stage_button.pressed.connect(_on_next_stage_pressed)
	continue_endless_button.pressed.connect(_on_continue_endless_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

const GHOST_ALERT_SCENE: PackedScene = preload("res://src/scenes/ui/popups/ghost_alert_popup.tscn")
const TUTORIAL_COMPLETE_SCENE: PackedScene = preload("res://src/scenes/ui/popups/tutorial_complete_popup.tscn")

func _on_stage_completed(completed_stage_id: String = "") -> void:
	if GameManager.current_stage and GameManager.current_stage.data:
		var stage = GameManager.current_stage
		var stage_data = stage.data
		var stage_id = completed_stage_id if not completed_stage_id.is_empty() else Registry.get_stage_id(stage_data)
		var lives = stage.lives
		var max_lives = stage_data.starting_lives
		var energy = stage.energy
		var score = stage.score
		
		var reward_info = SaveManager.record_stage_clear(stage_id, score, lives, max_lives)
		
		var stars: int = reward_info.get("stars", 1)
		star_1.modulate = STAR_EARNED_COLOR if stars >= 1 else STAR_UNEARNED_COLOR
		star_2.modulate = STAR_EARNED_COLOR if stars >= 2 else STAR_UNEARNED_COLOR
		star_3.modulate = STAR_EARNED_COLOR if stars >= 3 else STAR_UNEARNED_COLOR
		
		stats_label.text = "Remaining Lives: %d / %d\nFinal Energy: %d\nFinal Score: %d" % [lives, max_lives, energy, score]
		
		var is_first = reward_info.get("is_first_clear", false)
		var base_rew = reward_info.get("base_reward", 0)
		var star_rew = reward_info.get("star_bonus", 0)
		var total_rew = reward_info.get("total_reward", 0)
		
		if is_first:
			reward_breakdown_label.text = "First Clear: +%d Credits\nStar Bonus (%d★): +%d Credits\nTotal Earned: +%d Credits" % [
				base_rew, stars, star_rew, total_rew
			]
		elif star_rew > 0:
			reward_breakdown_label.text = "Repeat Clear: +%d Credits\nNew Star Bonus: +%d Credits\nTotal Earned: +%d Credits" % [
				base_rew, star_rew, total_rew
			]
		elif total_rew == 0:
			reward_breakdown_label.text = "Tutorial Replay: +0 Credits\nTotal Earned: +0 Credits"
		else:
			reward_breakdown_label.text = "Repeat Clear: +%d Credits\nTotal Earned: +%d Credits" % [
				base_rew, total_rew
			]
		
		var next_id = reward_info.get("next_stage_id", "")
		if not next_id.is_empty():
			next_unlock_label.show()
			var next_data = Registry.get_stage_data(next_id)
			var next_name = next_data.stage_name if next_data else next_id.capitalize()
			next_unlock_label.text = "New Stage Unlocked: %s" % next_name
		else:
			next_unlock_label.hide()
			
		var next_stage = GameManager.get_next_stage()
		next_stage_button.visible = (next_stage != null)
		
		show()
		
		if stage_id == "stage_00" and is_first:
			var tut_popup = TUTORIAL_COMPLETE_SCENE.instantiate()
			add_child(tut_popup)
			if tut_popup.has_method("open"):
				tut_popup.open()
		elif stage_id == "stage_02":
			var alert = GHOST_ALERT_SCENE.instantiate()
			add_child(alert)
			if alert.has_method("open"):
				alert.open()

func _on_next_stage_pressed() -> void:
	var next_stage: StageData = GameManager.get_next_stage()
	if next_stage:
		GameManager.selected_stage = next_stage
		GameManager.load_view(GameManager.View.LOADOUT)

func _on_continue_endless_pressed() -> void:
	GameManager.is_endless_mode = true
	hide()
	if GameManager.current_stage and GameManager.current_stage.wave_manager:
		var wm = GameManager.current_stage.wave_manager
		wm.is_stage_active = true
		wm.wave_is_active = false
		wm.update_upcoming_wave_preview()
		SignalBus.wave_changed.emit(wm.wave)
		SignalBus.wave_completed.emit()

func _on_retry_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_inventory_pressed() -> void:
	GameManager.target_main_menu_tab = 1 # NavBar.Tab.INVENTORY
	GameManager.load_view(GameManager.View.MAIN_MENU)

func _on_main_menu_pressed() -> void:
	GameManager.load_view(GameManager.View.MAIN_MENU)
