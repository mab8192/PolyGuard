extends CanvasLayer

@onready var star_rating_label: Label = %StarRatingLabel
@onready var stats_label: Label = %StatsLabel
@onready var reward_breakdown_label: Label = %RewardBreakdownLabel
@onready var next_unlock_label: Label = %NextUnlockLabel
@onready var next_stage_button: Button = %NextStageButton
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	hide()
	SignalBus.stage_completed.connect(_on_stage_completed)

	next_stage_button.pressed.connect(_on_next_stage_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_stage_completed() -> void:
	if GameManager.current_stage and GameManager.current_stage.data:
		var stage = GameManager.current_stage
		var stage_data = stage.data
		var stage_id = Registry.get_stage_id(stage_data)
		var lives = stage.lives
		var max_lives = stage_data.starting_lives
		var energy = stage.energy
		var score = stage.score
		
		var reward_info = SaveManager.record_stage_clear(stage_id, score, lives, max_lives)
		
		var stars = reward_info.get("stars", 1)
		star_rating_label.text = "%d STARS" % stars
		stats_label.text = "Remaining Lives: %d / %d\nFinal Energy: %d\nFinal Score: %d" % [lives, max_lives, energy, score]
		
		var clear_type_str = "First Clear Bonus" if reward_info.get("is_first_clear", false) else "Clear Reward"
		reward_breakdown_label.text = "%s: +%d Credits\nStar Bonus: +%d Credits\nTotal Earned: +%d Credits" % [
			clear_type_str,
			reward_info.get("base_reward", 0),
			reward_info.get("star_bonus", 0),
			reward_info.get("total_reward", 0)
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

func _on_next_stage_pressed() -> void:
	var next_stage: StageData = GameManager.get_next_stage()
	if next_stage:
		GameManager.selected_stage = next_stage
		GameManager.load_view(GameManager.View.LOADOUT)

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	GameManager.load_view(GameManager.View.MAIN_MENU)
