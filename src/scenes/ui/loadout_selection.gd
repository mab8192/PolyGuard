extends Control

@onready var stage_name_label: Label = %StageNameLabel
@onready var equipped_grid: GridContainer = %EquippedGrid
@onready var available_grid: GridContainer = %AvailableGrid
@onready var tower_name_label: Label = %TowerNameLabel
@onready var tower_stats_label: Label = %TowerStatsLabel
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton

@onready var preset_1_button: Button = %Preset1Button
@onready var preset_2_button: Button = %Preset2Button
@onready var preset_3_button: Button = %Preset3Button

var _equipped: Array[TowerData] = []
var _selected_slot_index: int = 0
var _active_preset_index: int = 1

func _get_max_slots() -> int:
	if GameManager.selected_stage and GameManager.selected_stage.loadout_size > 0:
		return GameManager.selected_stage.loadout_size
	return 4

func _ready() -> void:
	if AudioManager and AudioManager.music_menu:
		AudioManager.play_music(AudioManager.music_menu)

	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)

	preset_1_button.pressed.connect(func(): _select_preset(1))
	preset_2_button.pressed.connect(func(): _select_preset(2))
	preset_3_button.pressed.connect(func(): _select_preset(3))

	if GameManager.selected_stage:
		var st_name = GameManager.selected_stage.stage_name
		stage_name_label.text = st_name if st_name else "Selected Stage"
	else:
		stage_name_label.text = "Polygon Pass"

	_active_preset_index = GameManager.active_preset_index
	_load_preset(_active_preset_index)

func _select_preset(preset_num: int) -> void:
	GameManager.loadout_presets[_active_preset_index] = _equipped.duplicate()
	_active_preset_index = preset_num
	GameManager.active_preset_index = preset_num
	_load_preset(_active_preset_index)

func _load_preset(preset_num: int) -> void:
	var max_slots = _get_max_slots()
	if GameManager.loadout_presets.has(preset_num) and not (GameManager.loadout_presets[preset_num] as Array).is_empty():
		_equipped = (GameManager.loadout_presets[preset_num] as Array[TowerData]).duplicate()
		while _equipped.size() > max_slots:
			_equipped.pop_back()
	elif not GameManager.selected_loadout.is_empty():
		_equipped = GameManager.selected_loadout.duplicate()
		while _equipped.size() > max_slots:
			_equipped.pop_back()
	else:
		_equipped.clear()
		var all_towers = Registry.get_all_towers()
		for i in range(mini(max_slots, all_towers.size())):
			_equipped.append(all_towers[i])

	_render_ui()

func _update_preset_buttons() -> void:
	var buttons = [preset_1_button, preset_2_button, preset_3_button]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i + 1 == _active_preset_index:
			btn.modulate = Color(0.3, 1.0, 0.75, 1.0)
		else:
			btn.modulate = Color.WHITE

func _render_ui() -> void:
	_update_preset_buttons()
	_render_equipped_slots()
	_render_available_towers()
	_update_tower_details()

func _create_card_button(t_data: TowerData, is_equipped_check: bool, is_selected: bool, is_slot: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 220)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	if t_data != null:
		# Icon aligned to center
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(75, 75)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if t_data.icon:
			icon_rect.texture = t_data.icon
		else:
			icon_rect.texture = preload("res://vendor/HAMMA.png")
		vbox.add_child(icon_rect)

		# Display Name
		var name_lbl = Label.new()
		name_lbl.text = t_data.display_name
		name_lbl.theme_type_variation = &"CardTitle"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(1, 0)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_lbl)

		# Gold cost without "Cost: " prefix
		var cost_lbl = Label.new()
		cost_lbl.text = "%dg" % t_data.cost
		cost_lbl.theme_type_variation = &"CostLabel"
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.custom_minimum_size = Vector2(1, 0)
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(cost_lbl)

		# Top right checkmark for equipped towers in available grid
		if is_equipped_check and not is_slot:
			var check_lbl = Label.new()
			check_lbl.text = "✓"
			check_lbl.theme_type_variation = &"HeaderLabel"
			check_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.75, 1.0))
			check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			check_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			check_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			check_lbl.offset_right = -8
			check_lbl.offset_top = 2
			btn.add_child(check_lbl)
			btn.modulate = Color(0.75, 0.95, 0.85, 0.9)
		elif is_selected:
			btn.modulate = Color(0.3, 1.0, 0.75, 1.0)
		else:
			btn.modulate = Color.WHITE
	else:
		var empty_lbl = Label.new()
		empty_lbl.text = "+ Equip"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.custom_minimum_size = Vector2(1, 0)
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(empty_lbl)

		if is_selected:
			btn.modulate = Color(0.3, 1.0, 0.75, 1.0)
		else:
			btn.modulate = Color.WHITE

	return btn

func _render_equipped_slots() -> void:
	for child in equipped_grid.get_children():
		child.queue_free()

	var max_slots = _get_max_slots()
	for i in range(max_slots):
		var t_data: TowerData = null
		if i < _equipped.size():
			t_data = _equipped[i]

		var is_selected = (i == _selected_slot_index)
		var btn = _create_card_button(t_data, false, is_selected, true)

		var slot_idx = i
		btn.pressed.connect(func(): _on_slot_clicked(slot_idx))
		equipped_grid.add_child(btn)

func _render_available_towers() -> void:
	for child in available_grid.get_children():
		child.queue_free()

	var all_towers = Registry.get_all_towers()
	for t_data in all_towers:
		var is_equipped = _equipped.has(t_data)
		var btn = _create_card_button(t_data, is_equipped, false, false)

		var tower_ref = t_data
		btn.pressed.connect(func(): _equip_tower(tower_ref))
		available_grid.add_child(btn)

func _on_slot_clicked(idx: int) -> void:
	_selected_slot_index = idx
	_render_ui()

func _equip_tower(t_data: TowerData) -> void:
	var max_slots = _get_max_slots()
	if _equipped.has(t_data):
		var existing_idx = _equipped.find(t_data)
		if existing_idx != _selected_slot_index and _selected_slot_index < _equipped.size():
			var temp = _equipped[_selected_slot_index]
			_equipped[_selected_slot_index] = t_data
			_equipped[existing_idx] = temp
	else:
		if _selected_slot_index < _equipped.size():
			_equipped[_selected_slot_index] = t_data
		elif _equipped.size() < max_slots:
			_equipped.append(t_data)

	GameManager.loadout_presets[_active_preset_index] = _equipped.duplicate()
	_render_ui()

func _update_tower_details() -> void:
	if _selected_slot_index < _equipped.size() and _equipped[_selected_slot_index] != null:
		var t = _equipped[_selected_slot_index]
		tower_name_label.text = t.display_name
		var stats_str: String = "Cost: %dg" % t.cost
		if t.attack:
			stats_str += "  |  Dmg: %d" % int(t.attack.damage)
		if t.health:
			stats_str += "  |  HP: %d" % int(t.health.max_health)
		if not t.description.is_empty():
			stats_str += "\n" + t.description
		tower_stats_label.text = stats_str
	else:
		tower_name_label.text = "Slot %d (Empty)" % (_selected_slot_index + 1)
		tower_stats_label.text = "Select a tower from available arsenal below to equip."

func _on_start_pressed() -> void:
	GameManager.selected_loadout = _equipped.duplicate()
	GameManager.loadout_presets[_active_preset_index] = _equipped.duplicate()
	GameManager.start_game(GameManager.selected_stage, _equipped)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/ui/stage_select.tscn")
