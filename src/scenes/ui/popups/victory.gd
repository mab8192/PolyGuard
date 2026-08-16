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

func _on_next_stage_pressed() -> void:
	var next_stage: StageData = GameManager.get_next_stage()
	if next_stage:
		GameManager.selected_stage = next_stage
		GameManager.load_view(GameManager.View.LOADOUT)

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	GameManager.load_view(GameManager.View.MAIN_MENU)
