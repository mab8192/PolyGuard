extends Control

const MAX_SLOTS = 4

@onready var stage_name_label: Label = %StageNameLabel
@onready var equipped_container: HBoxContainer = %EquippedContainer
@onready var available_grid: GridContainer = %AvailableGrid
@onready var tower_name_label: Label = %TowerNameLabel
@onready var tower_stats_label: Label = %TowerStatsLabel
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton

var _equipped: Array[TowerData] = []
var _selected_slot_index: int = 0

func _ready() -> void:
	if AudioManager and AudioManager.music_menu:
		AudioManager.play_music(AudioManager.music_menu)

	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)

	if GameManager.selected_stage:
		var st_name = GameManager.selected_stage.stage_name
		stage_name_label.text = st_name if st_name else "Selected Stage"
	else:
		stage_name_label.text = "Polygon Pass"

	# Initialize equipped loadout from GameManager or defaults
	if not GameManager.selected_loadout.is_empty():
		_equipped = GameManager.selected_loadout.duplicate()
	else:
		var all_towers = Registry.get_all_towers()
		for i in range(mini(MAX_SLOTS, all_towers.size())):
			_equipped.append(all_towers[i])

	_render_ui()

func _render_ui() -> void:
	_render_equipped_slots()
	_render_available_towers()
	_update_tower_details()

func _render_equipped_slots() -> void:
	for child in equipped_container.get_children():
		child.queue_free()

	for i in range(MAX_SLOTS):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 160)
		
		if i < _equipped.size() and _equipped[i] != null:
			var t_data = _equipped[i]
			btn.text = "%s\n%dg" % [t_data.display_name, t_data.cost]
			if t_data.icon:
				btn.icon = t_data.icon
				btn.expand_icon = true
		else:
			btn.text = "+ Equip"

		if i == _selected_slot_index:
			btn.modulate = Color(0.3, 1.0, 0.7, 1.0)
		else:
			btn.modulate = Color.WHITE

		var slot_idx = i
		btn.pressed.connect(func(): _on_slot_clicked(slot_idx))
		equipped_container.add_child(btn)

func _render_available_towers() -> void:
	for child in available_grid.get_children():
		child.queue_free()

	var all_towers = Registry.get_all_towers()
	for t_data in all_towers:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 160)
		
		var is_equipped = _equipped.has(t_data)
		if is_equipped:
			btn.text = "%s (Equipped)" % t_data.display_name
			btn.modulate = Color(0.6, 0.6, 0.6, 0.8)
		else:
			btn.text = "%s\nCost: %dg" % [t_data.display_name, t_data.cost]

		if t_data.icon:
			btn.icon = t_data.icon
			btn.expand_icon = true

		var tower_ref = t_data
		btn.pressed.connect(func(): _equip_tower(tower_ref))
		available_grid.add_child(btn)

func _on_slot_clicked(idx: int) -> void:
	_selected_slot_index = idx
	_render_ui()

func _equip_tower(t_data: TowerData) -> void:
	# If tower is already equipped somewhere else, swap or ignore
	if _equipped.has(t_data):
		var existing_idx = _equipped.find(t_data)
		if existing_idx != _selected_slot_index and _selected_slot_index < _equipped.size():
			# Swap
			var temp = _equipped[_selected_slot_index]
			_equipped[_selected_slot_index] = t_data
			_equipped[existing_idx] = temp
	else:
		if _selected_slot_index < _equipped.size():
			_equipped[_selected_slot_index] = t_data
		elif _equipped.size() < MAX_SLOTS:
			_equipped.append(t_data)

	_render_ui()

func _update_tower_details() -> void:
	if _selected_slot_index < _equipped.size() and _equipped[_selected_slot_index] != null:
		var t = _equipped[_selected_slot_index]
		tower_name_label.text = t.display_name
		tower_stats_label.text = "Cost: %dg  |  Type: Tower" % t.cost
	else:
		tower_name_label.text = "Slot %d" % (_selected_slot_index + 1)
		tower_stats_label.text = "Select a tower from below to equip"

func _on_start_pressed() -> void:
	GameManager.selected_loadout = _equipped.duplicate()
	GameManager.start_game(GameManager.selected_stage, _equipped)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/ui/stage_select.tscn")
