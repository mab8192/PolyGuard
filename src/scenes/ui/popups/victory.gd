extends CanvasLayer

@onready var stats_label: Label = %StatsLabel
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
	if GameManager.current_stage:
		var lives = GameManager.current_stage.lives
		var gold = GameManager.current_stage.gold
		var score = GameManager.current_stage.score
		stats_label.text = "Remaining Lives: %d\nFinal Gold: %d\nFinal Score: %d" % [lives, gold, score]
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
