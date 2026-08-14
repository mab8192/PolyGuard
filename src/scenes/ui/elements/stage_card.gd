class_name StageCard extends PanelContainer

signal stage_selected(stage: StageData)

var stage_data: StageData

@onready var preview_texture: TextureRect = %PreviewTexture
@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var start_button: Button = %StartButton

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_on_gui_input)
	
	if stage_data:
		_render()
	
	if start_button:
		start_button.pressed.connect(_on_card_pressed)

func setup(p_stage: StageData) -> void:
	stage_data = p_stage
	if is_inside_tree():
		_render()

func _render() -> void:
	if not stage_data:
		return
	
	if preview_texture and stage_data.icon:
		preview_texture.texture = stage_data.icon
	
	if title_label:
		title_label.text = stage_data.stage_name
	
	if stats_label:
		var wave_count := stage_data.get_waves().size()
		var stat_parts: Array[String] = []
		
		stat_parts.append("Gold: %d" % stage_data.starting_gold)
		stat_parts.append("Lives: %d" % stage_data.starting_lives)
		
		if wave_count > 0:
			stat_parts.append("Waves: %d" % wave_count)
			
		var slots := stage_data.loadout_size if stage_data.loadout_size > 0 else 4
		stat_parts.append("Slots: %d" % slots)
		
		stats_label.text = " • ".join(stat_parts)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_card_pressed()

func _on_card_pressed() -> void:
	if stage_data:
		stage_selected.emit(stage_data)
