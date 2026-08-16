class_name StageCard extends PanelContainer

signal stage_selected(stage: StageData)

const STAR_EARNED_COLOR := Color(1.0, 0.82, 0.22, 1.0)
const STAR_UNEARNED_COLOR := Color(0.28, 0.32, 0.42, 0.45)

var stage_data: StageData

@onready var preview_texture: TextureRect = %PreviewTexture
@onready var title_label: Label = %TitleLabel
@onready var stars_container: HBoxContainer = %StarsContainer
@onready var star_1: TextureRect = %Star1
@onready var star_2: TextureRect = %Star2
@onready var star_3: TextureRect = %Star3
@onready var stats_label: Label = %StatsLabel
@onready var record_label: Label = %RecordLabel
@onready var status_badge_container: PanelContainer = %StatusBadgeContainer
@onready var status_badge_label: Label = %StatusBadgeLabel
@onready var start_button: Button = %StartButton

func _ready() -> void:
	if stage_data:
		_render()
	
	gui_input.connect(_on_gui_input)
	if start_button:
		start_button.pressed.connect(_on_card_pressed)

func setup(p_stage: StageData) -> void:
	stage_data = p_stage
	if is_inside_tree():
		_render()

func _render() -> void:
	if not stage_data:
		return
	
	var stage_id = Registry.get_stage_id(stage_data)
	var is_unlocked = SaveManager.is_stage_unlocked(stage_id)
	var record = SaveManager.get_stage_record(stage_id)
	
	if preview_texture and stage_data.icon:
		preview_texture.texture = stage_data.icon
	
	if title_label:
		title_label.text = stage_data.stage_name
	
	if stats_label:
		var wave_count := stage_data.get_waves().size()
		var stat_parts: Array[String] = []
		
		stat_parts.append("Energy: %d" % stage_data.starting_energy)
		stat_parts.append("Lives: %d" % stage_data.starting_lives)
		
		if wave_count > 0:
			stat_parts.append("Waves: %d" % wave_count)
			
		var slots := stage_data.loadout_size if stage_data.loadout_size > 0 else 4
		stat_parts.append("Slots: %d" % slots)
		
		stats_label.text = " • ".join(stat_parts)

	if is_unlocked:
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		start_button.disabled = false
		start_button.theme_type_variation = &"PrimaryButton"
		
		if record.get("completed", false):
			var stars: int = record.get("stars", 1)
			if stars_container:
				stars_container.show()
				star_1.modulate = STAR_EARNED_COLOR if stars >= 1 else STAR_UNEARNED_COLOR
				star_2.modulate = STAR_EARNED_COLOR if stars >= 2 else STAR_UNEARNED_COLOR
				star_3.modulate = STAR_EARNED_COLOR if stars >= 3 else STAR_UNEARNED_COLOR
			if status_badge_container:
				status_badge_container.hide()
			record_label.text = "Best Score: %d" % record.get("high_score", 0)
			start_button.text = "REPLAY"
		else:
			if stars_container:
				stars_container.hide()
			if status_badge_container:
				status_badge_container.show()
				status_badge_container.theme_type_variation = &"TypeBadge"
				status_badge_label.text = "AVAILABLE"
			record_label.text = "First Clear: 400 Credits"
			start_button.text = "START"
	else:
		self_modulate = Color(0.7, 0.7, 0.7, 0.5)
		if stars_container:
			stars_container.hide()
		if status_badge_container:
			status_badge_container.show()
			status_badge_container.theme_type_variation = &"LockedBadge"
			status_badge_label.text = "LOCKED"
		record_label.text = "Clear previous stage to unlock"
		start_button.disabled = true
		start_button.text = "LOCKED"
		start_button.theme_type_variation = &"SecondaryButton"

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_on_card_pressed()

func _on_card_pressed() -> void:
	if DragScrollContainer.is_globally_dragging:
		return
	if stage_data:
		var stage_id = Registry.get_stage_id(stage_data)
		if SaveManager.is_stage_unlocked(stage_id):
			stage_selected.emit(stage_data)

