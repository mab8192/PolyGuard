extends Control

@onready var stage_container: VBoxContainer = %StageListContainer
@onready var continue_button: Button = %ContinueButton
@onready var back_button: Button = %BackButton
@onready var selected_stage_label: Label = %SelectedStageLabel

var _selected_stage: StageData = null

func _ready() -> void:
	if AudioManager and AudioManager.music_menu:
		AudioManager.play_music(AudioManager.music_menu)

	back_button.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	_populate_stages()

func _populate_stages() -> void:
	for child in stage_container.get_children():
		child.queue_free()

	var stages: Array[StageData] = Registry.get_all_stages()
	if stages.is_empty():
		selected_stage_label.text = "No stages found in Registry!"
		continue_button.disabled = true
		return

	# Default selection to current or first stage
	if GameManager.selected_stage and stages.has(GameManager.selected_stage):
		_select_stage(GameManager.selected_stage)
	else:
		_select_stage(stages[0])

	for stage_data in stages:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 110)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = "%s\nGold: %d  |  Lives: %d  |  Waves: %d" % [
			stage_data.stage_name,
			stage_data.starting_gold,
			stage_data.starting_lives,
			stage_data.get_waves().size()
		]
		
		btn.pressed.connect(func(): _select_stage(stage_data))
		stage_container.add_child(btn)

func _select_stage(stage_data: StageData) -> void:
	_selected_stage = stage_data
	GameManager.selected_stage = stage_data
	var name_str = stage_data.stage_name
	selected_stage_label.text = "Selected: " + name_str
	continue_button.disabled = false

func _on_continue_pressed() -> void:
	if _selected_stage:
		get_tree().change_scene_to_file("res://src/scenes/ui/loadout_selection.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/ui/main_menu.tscn")
