class_name LoadoutSelectionView extends Control

const SLOT_SCENE: PackedScene = preload("res://src/scenes/ui/elements/loadout_slot.tscn")
const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/loadout_card.tscn")

# Stage & Rules
var current_stage: StageData
var max_loadout_size: int = 4
var equipped_towers: Array[TowerData] = []
var all_towers: Array[TowerData] = []
var selected_tower: TowerData = null

# Node references
@onready var back_button: Button = %BackButton
@onready var stage_title_label: Label = %StageTitleLabel
@onready var stage_subtitle_label: Label = %StageSubtitleLabel
@onready var loadout_count_label: Label = %LoadoutCountLabel
@onready var clear_all_button: Button = %ClearAllButton
@onready var loadout_slots_container: HBoxContainer = %LoadoutSlotsContainer
@onready var available_grid: GridContainer = %AvailableGrid
@onready var start_battle_button: Button = %StartBattleButton

# Details Panel
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_cost: Label = %DetailCost
@onready var detail_level_badge: Label = %DetailLevelBadge
@onready var detail_type_badge: Label = %DetailTypeBadge
@onready var detail_desc: Label = %DetailDesc
@onready var detail_stats: Label = %DetailStats
@onready var detail_action_button: Button = %DetailActionButton

func _ready() -> void:
	all_towers = Registry.get_all_towers_sorted()
	_init_stage_data()
	_init_loadout()
	
	back_button.pressed.connect(_on_back_pressed)
	clear_all_button.pressed.connect(_on_clear_all_pressed)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	detail_action_button.pressed.connect(_on_detail_action_pressed)
	
	SignalBus.credits_changed.connect(func(_c): _refresh_all())
	SignalBus.tower_unlocked.connect(func(_t): _refresh_all())
	
	_refresh_all()

func _init_stage_data() -> void:
	current_stage = GameManager.selected_stage
	if not current_stage:
		var stages = Registry.get_all_stages()
		if not stages.is_empty():
			current_stage = stages[0]
			GameManager.selected_stage = current_stage
	
	if current_stage:
		max_loadout_size = current_stage.loadout_size if current_stage.loadout_size > 0 else 4
	else:
		max_loadout_size = 4

func _init_loadout() -> void:
	equipped_towers.clear()
	
	var unlocked_towers: Array[TowerData] = []
	for t in all_towers:
		var t_id = Registry.get_tower_id(t)
		if SaveManager.is_tower_unlocked(t_id):
			unlocked_towers.append(t)
	
	var saved_ids = SaveManager.get_selected_loadout()
	if not saved_ids.is_empty():
		for t_id in saved_ids:
			if SaveManager.is_tower_unlocked(t_id):
				var matching_tower: TowerData = null
				for t in all_towers:
					if Registry.get_tower_id(t) == t_id:
						matching_tower = t
						break
				if matching_tower and unlocked_towers.has(matching_tower) and not equipped_towers.has(matching_tower):
					if equipped_towers.size() < max_loadout_size:
						equipped_towers.append(matching_tower)
	
	if equipped_towers.is_empty() and not GameManager.selected_loadout.is_empty():
		for tower in GameManager.selected_loadout:
			var matching_tower = _find_matching_tower(tower)
			if matching_tower and unlocked_towers.has(matching_tower) and not equipped_towers.has(matching_tower):
				if equipped_towers.size() < max_loadout_size:
					equipped_towers.append(matching_tower)
	
	# If still empty, auto-populate with initial unlocked towers up to capacity
	if equipped_towers.is_empty():
		var count = mini(max_loadout_size, unlocked_towers.size())
		for i in range(count):
			equipped_towers.append(unlocked_towers[i])
			
	if not equipped_towers.is_empty():
		selected_tower = equipped_towers[0]
	elif not all_towers.is_empty():
		selected_tower = all_towers[0]

func _find_matching_tower(tower: TowerData) -> TowerData:
	if not tower:
		return null
	var t_id = Registry.get_tower_id(tower)
	for t in all_towers:
		if Registry.get_tower_id(t) == t_id:
			return t
	return null

func _refresh_all() -> void:
	all_towers = Registry.get_all_towers_sorted()
	_update_header()
	_render_loadout_slots()
	_render_available_grid()
	_update_details_panel()

func _update_header() -> void:
	if current_stage:
		stage_title_label.text = current_stage.stage_name.to_upper()
		stage_subtitle_label.text = "Starting Energy: %d  •  Base Lives: %d" % [current_stage.starting_energy, current_stage.starting_lives]
	else:
		stage_title_label.text = "CUSTOM LOADOUT"
		stage_subtitle_label.text = "Select your defensive arsenal"
		
	loadout_count_label.text = "EQUIPPED LOADOUT (%d / %d)" % [equipped_towers.size(), max_loadout_size]
	clear_all_button.disabled = (equipped_towers.size() == 0)
	start_battle_button.disabled = (equipped_towers.size() == 0)

func _render_loadout_slots() -> void:
	for child in loadout_slots_container.get_children():
		child.queue_free()
		
	for i in range(max_loadout_size):
		var slot: LoadoutSlot = SLOT_SCENE.instantiate() as LoadoutSlot
		loadout_slots_container.add_child(slot)
		
		var tower: TowerData = equipped_towers[i] if i < equipped_towers.size() else null
		slot.setup(i, tower)
		slot.set_selected(tower != null and tower == selected_tower)
		
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.remove_clicked.connect(_on_slot_remove_clicked)

func _render_available_grid() -> void:
	for child in available_grid.get_children():
		child.queue_free()
		
	for tower in all_towers:
		var card: LoadoutCard = CARD_SCENE.instantiate() as LoadoutCard
		available_grid.add_child(card)
		
		var is_equipped = equipped_towers.has(tower)
		card.setup_as_available(tower, is_equipped)
		card.set_card_selected(tower == selected_tower)
		
		card.card_clicked.connect(_on_available_card_clicked)

func _update_details_panel() -> void:
	if not selected_tower:
		if not equipped_towers.is_empty():
			selected_tower = equipped_towers[0]
		elif not all_towers.is_empty():
			selected_tower = all_towers[0]
			
	if not selected_tower:
		detail_title.text = "NO TOWER SELECTED"
		detail_desc.text = "Select a tower to view its attributes."
		detail_stats.text = ""
		detail_cost.text = ""
		detail_level_badge.text = ""
		detail_type_badge.text = ""
		detail_action_button.disabled = true
		detail_action_button.text = "NO SELECTION"
		return
		
	var t_id = Registry.get_tower_id(selected_tower)
	var is_unlocked = SaveManager.is_tower_unlocked(t_id)
	var level = SaveManager.get_tower_level(t_id) if is_unlocked else 1
	var active_choice = SaveManager.get_tower_choice(t_id)
	var stats = selected_tower.get_stats(level, active_choice)
	
	var is_avail = selected_tower.is_available()
	
	detail_icon.texture = selected_tower.icon
	detail_title.text = selected_tower.display_name
	detail_cost.text = "%d Energy" % selected_tower.cost
	
	var base_desc = selected_tower.description if not selected_tower.description.is_empty() else "Defensive structure ready for deployment."
	if not is_unlocked and not is_avail:
		var req_desc = selected_tower.get_requirement_description()
		detail_desc.text = "%s  [%s]" % [base_desc, req_desc] if not req_desc.is_empty() else base_desc
		detail_icon.modulate = Color(0.35, 0.38, 0.45, 0.5)
	elif not is_unlocked:
		detail_desc.text = base_desc
		detail_icon.modulate = Color(0.5, 0.55, 0.65, 0.7)
	else:
		detail_desc.text = base_desc
		detail_icon.modulate = Color.WHITE
	
	if is_unlocked:
		if detail_level_badge.get_parent():
			detail_level_badge.get_parent().theme_type_variation = &"StatusBadge"
		detail_level_badge.text = "LEVEL %d" % level
	elif not is_avail:
		if detail_level_badge.get_parent():
			detail_level_badge.get_parent().theme_type_variation = &"UnavailableBadge"
		detail_level_badge.text = "UNAVAILABLE"
	else:
		if detail_level_badge.get_parent():
			detail_level_badge.get_parent().theme_type_variation = &"LockedBadge"
		detail_level_badge.text = "LOCKED"
		
	detail_type_badge.text = (stats.get("type", "DEFENSE")).to_upper()
		
	var stat_lines: Array[String] = stats.get("stat_lines", [])
	detail_stats.text = "   •   ".join(stat_lines)
	
	# Action Button
	if not is_unlocked:
		if not is_avail:
			var req_desc = selected_tower.get_requirement_description()
			if not req_desc.is_empty():
				detail_action_button.text = "LOCKED (%s)" % req_desc.to_upper()
			else:
				detail_action_button.text = "UNAVAILABLE (STAGE LOCKED)"
			detail_action_button.disabled = true
			detail_action_button.theme_type_variation = &"SecondaryButton"
		else:
			var cost = selected_tower.unlock_cost
			var credits = SaveManager.get_credits()
			if credits >= cost:
				detail_action_button.text = "UNLOCK (%d CREDITS)" % cost
				detail_action_button.disabled = false
				detail_action_button.theme_type_variation = &"PrimaryButton"
			else:
				detail_action_button.text = "UNLOCK (%d CREDITS)" % cost
				detail_action_button.disabled = true
				detail_action_button.theme_type_variation = &"SecondaryButton"
	else:
		var is_in_loadout = equipped_towers.has(selected_tower)
		if is_in_loadout:
			detail_action_button.text = "REMOVE FROM LOADOUT"
			detail_action_button.disabled = false
			detail_action_button.theme_type_variation = &"DangerButton"
		else:
			if equipped_towers.size() >= max_loadout_size:
				detail_action_button.text = "LOADOUT FULL (%d / %d)" % [equipped_towers.size(), max_loadout_size]
				detail_action_button.disabled = true
				detail_action_button.theme_type_variation = &"SecondaryButton"
			else:
				detail_action_button.text = "+ EQUIP TO LOADOUT"
				detail_action_button.disabled = false
				detail_action_button.theme_type_variation = &"PrimaryButton"

func _on_slot_clicked(slot: LoadoutSlot) -> void:
	if slot.tower_data:
		selected_tower = slot.tower_data
		_refresh_all()

func _save_current_loadout() -> void:
	var ids: Array[String] = []
	for tower in equipped_towers:
		var t_id = Registry.get_tower_id(tower)
		if not t_id.is_empty():
			ids.append(t_id)
	SaveManager.set_selected_loadout(ids)

func _on_slot_remove_clicked(slot: LoadoutSlot) -> void:
	if slot.tower_data:
		_remove_tower_from_loadout(slot.tower_data)

func _on_available_card_clicked(card: LoadoutCard) -> void:
	selected_tower = card.tower_data
	var t_id = Registry.get_tower_id(card.tower_data)
	if SaveManager.is_tower_unlocked(t_id):
		if not equipped_towers.has(card.tower_data):
			if equipped_towers.size() < max_loadout_size:
				equipped_towers.append(card.tower_data)
				_save_current_loadout()
	_refresh_all()

func _on_detail_action_pressed() -> void:
	if not selected_tower:
		return
	var t_id = Registry.get_tower_id(selected_tower)
	var is_unlocked = SaveManager.is_tower_unlocked(t_id)
	
	if not is_unlocked:
		if not selected_tower.is_available():
			return
		var unlocked = SaveManager.unlock_tower(t_id, selected_tower.unlock_cost)
		if unlocked:
			if equipped_towers.size() < max_loadout_size:
				equipped_towers.append(selected_tower)
				_save_current_loadout()
			_refresh_all()
	else:
		if equipped_towers.has(selected_tower):
			_remove_tower_from_loadout(selected_tower)
		else:
			if equipped_towers.size() < max_loadout_size:
				equipped_towers.append(selected_tower)
				_save_current_loadout()
				_refresh_all()

func _remove_tower_from_loadout(tower: TowerData) -> void:
	equipped_towers.erase(tower)
	_save_current_loadout()
	_refresh_all()

func _on_clear_all_pressed() -> void:
	equipped_towers.clear()
	_save_current_loadout()
	_refresh_all()

func _on_back_pressed() -> void:
	_save_current_loadout()
	GameManager.load_view(GameManager.View.MAIN_MENU)

func _on_start_battle_pressed() -> void:
	if equipped_towers.is_empty():
		return
		
	_save_current_loadout()
	var battle_loadout: Array[TowerData] = []
	for tower in equipped_towers:
		var t_id = Registry.get_tower_id(tower)
		var lvl = SaveManager.get_tower_level(t_id)
		var choice = SaveManager.get_tower_choice(t_id)
		var scaled = tower.get_scaled_copy(lvl, choice)
		battle_loadout.append(scaled)
		
	GameManager.selected_loadout = battle_loadout
	GameManager.load_view(GameManager.View.GAME)
