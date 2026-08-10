extends Control

@onready var stage_container: GridContainer = %StageGridContainer
@onready var back_button: Button = %BackButton

func _ready() -> void:
	if AudioManager and AudioManager.music_menu:
		AudioManager.play_music(AudioManager.music_menu)

	back_button.pressed.connect(_on_back_pressed)
	_populate_stages()

func _populate_stages() -> void:
	for child in stage_container.get_children():
		child.queue_free()

	var stages: Array[StageData] = Registry.get_all_stages()
	if stages.is_empty():
		return

	for stage_data in stages:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 260)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var margin = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(margin)

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(vbox)

		# Icon
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(90, 90)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if stage_data.icon:
			icon_rect.texture = stage_data.icon
		else:
			icon_rect.texture = preload("res://vendor/HAMMA.png")
		vbox.add_child(icon_rect)

		# Name
		var name_label = Label.new()
		name_label.text = stage_data.stage_name
		name_label.theme_type_variation = &"CardTitle"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.custom_minimum_size = Vector2(1, 0)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_label)

		# Stats / Details
		var info_label = Label.new()
		var wave_count = stage_data.get_waves().size()
		info_label.text = "Gold: %d | Lives: %d | Waves: %d" % [
			stage_data.starting_gold,
			stage_data.starting_lives,
			wave_count
		]
		info_label.theme_type_variation = &"CostLabel"
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_label.custom_minimum_size = Vector2(1, 0)
		info_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95, 1.0))
		info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(info_label)

		var st_ref = stage_data
		btn.pressed.connect(func(): _on_stage_clicked(st_ref))
		stage_container.add_child(btn)

func _on_stage_clicked(stage_data: StageData) -> void:
	GameManager.selected_stage = stage_data
	get_tree().change_scene_to_file("res://src/scenes/ui/loadout_selection.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/ui/main_menu.tscn")
