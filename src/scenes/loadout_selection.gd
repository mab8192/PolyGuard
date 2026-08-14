class_name LoadoutSelectionView extends Control

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
@onready var loadout_grid: GridContainer = %LoadoutGrid
@onready var available_grid: GridContainer = %AvailableGrid
@onready var start_battle_button: Button = %StartBattleButton

# Details Panel
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_cost: Label = %DetailCost
@onready var detail_type_badge: Label = %DetailTypeBadge
@onready var detail_desc: Label = %DetailDesc
@onready var detail_stats: Label = %DetailStats
@onready var detail_action_button: Button = %DetailActionButton

func _ready() -> void:
	all_towers = Registry.get_all_towers()
	_init_stage_data()
	_init_loadout()
	
	back_button.pressed.connect(_on_back_pressed)
	clear_all_button.pressed.connect(_on_clear_all_pressed)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	detail_action_button.pressed.connect(_on_detail_action_pressed)
	
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
	
	if not GameManager.selected_loadout.is_empty():
		for tower in GameManager.selected_loadout:
			if tower and all_towers.has(tower) and not equipped_towers.has(tower):
				if equipped_towers.size() < max_loadout_size:
					equipped_towers.append(tower)
	
	# If still empty, auto-populate with initial available towers up to capacity
	if equipped_towers.is_empty():
		var count = mini(max_loadout_size, all_towers.size())
		for i in range(count):
			equipped_towers.append(all_towers[i])
			
	if not equipped_towers.is_empty():
		selected_tower = equipped_towers[0]
	elif not all_towers.is_empty():
		selected_tower = all_towers[0]

func _refresh_all() -> void:
	_update_header()
	_render_loadout_grid()
	_render_available_grid()
	_update_details_panel()

func _update_header() -> void:
	if current_stage:
		stage_title_label.text = current_stage.stage_name.to_upper()
		stage_subtitle_label.text = "Starting Gold: %dg  •  Base Lives: %d" % [current_stage.starting_gold, current_stage.starting_lives]
	else:
		stage_title_label.text = "CUSTOM LOADOUT"
		stage_subtitle_label.text = "Select your defensive arsenal"
		
	loadout_count_label.text = "CURRENT LOADOUT (%d / %d)" % [equipped_towers.size(), max_loadout_size]
	clear_all_button.disabled = (equipped_towers.size() == 0)
	start_battle_button.disabled = (equipped_towers.size() == 0)

func _render_loadout_grid() -> void:
	for child in loadout_grid.get_children():
		child.queue_free()
		
	for i in range(max_loadout_size):
		var card: LoadoutCard = CARD_SCENE.instantiate() as LoadoutCard
		loadout_grid.add_child(card)
		
		var tower: TowerData = equipped_towers[i] if i < equipped_towers.size() else null
		card.setup_as_slot(i, tower)
		card.set_card_selected(tower != null and tower == selected_tower)
		
		card.card_clicked.connect(_on_slot_card_clicked)
		card.remove_clicked.connect(_on_slot_remove_clicked)

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
		detail_desc.text = "Select a tower from the grids above or below to view its attributes."
		detail_stats.text = ""
		detail_cost.text = ""
		detail_type_badge.text = ""
		detail_action_button.disabled = true
		detail_action_button.text = "NO SELECTION"
		return
		
	detail_icon.texture = selected_tower.icon
	detail_title.text = selected_tower.display_name
	detail_cost.text = "%dg" % selected_tower.cost
	detail_desc.text = selected_tower.description if not selected_tower.description.is_empty() else "Defensive structure ready for deployment."
	
	# Structure Type
	if selected_tower.is_solid:
		detail_type_badge.text = "SOLID DEFENSE"
	else:
		detail_type_badge.text = "GROUND TRAP"
		
	# Build Stats Summary
	var stat_lines: Array[String] = []
	
	if selected_tower.attack:
		var dmg_str = "%.0f" % selected_tower.attack.damage
		var cd_str = "%.2fs" % selected_tower.attack.cooldown
		var dps = selected_tower.attack.damage / maxf(selected_tower.attack.cooldown, 0.05)
		stat_lines.append("Damage: %s (%s DPS)" % [dmg_str, "%.1f" % dps])
		stat_lines.append("Rate: Every %s" % cd_str)
	
	if selected_tower.targeting:
		var strat_name = _get_strategy_name(selected_tower.targeting.strategy)
		stat_lines.append("Target: %s (Max: %d)" % [strat_name, selected_tower.targeting.max_targets])
		
	if selected_tower.health:
		stat_lines.append("Max HP: %.0f" % selected_tower.health.max_health)
		
	if selected_tower.effect_applier and not selected_tower.effect_applier.effects.is_empty():
		stat_lines.append("Applies Effects")
		
	if stat_lines.is_empty():
		stat_lines.append("Defensive Obstacle (Blocks enemy movement)")
		
	detail_stats.text = " | ".join(stat_lines)
	
	# Configure Action Button
	var is_in_loadout = equipped_towers.has(selected_tower)
	if is_in_loadout:
		detail_action_button.text = "REMOVE FROM LOADOUT"
		detail_action_button.disabled = false
		detail_action_button.theme_type_variation = &"DangerButton"
	else:
		if equipped_towers.size() >= max_loadout_size:
			detail_action_button.text = "LOADOUT FULL (%d/%d)" % [equipped_towers.size(), max_loadout_size]
			detail_action_button.disabled = true
			detail_action_button.theme_type_variation = &"SecondaryButton"
		else:
			detail_action_button.text = "+ EQUIP TO LOADOUT"
			detail_action_button.disabled = false
			detail_action_button.theme_type_variation = &"PrimaryButton"

func _get_strategy_name(strategy: TargetingComponent.Strategy) -> String:
	match strategy:
		TargetingComponent.Strategy.FIRST: return "First"
		TargetingComponent.Strategy.LAST: return "Last"
		TargetingComponent.Strategy.CLOSEST: return "Strongest"
		TargetingComponent.Strategy.STRONGEST: return "Strongest"
		_: return "Error"

func _on_slot_card_clicked(card: LoadoutCard) -> void:
	if card.tower_data:
		selected_tower = card.tower_data
		_refresh_all()

func _on_slot_remove_clicked(card: LoadoutCard) -> void:
	if card.tower_data:
		_remove_tower_from_loadout(card.tower_data)

func _on_available_card_clicked(card: LoadoutCard) -> void:
	selected_tower = card.tower_data
	if not equipped_towers.has(card.tower_data):
		if equipped_towers.size() < max_loadout_size:
			equipped_towers.append(card.tower_data)
	_refresh_all()

func _on_detail_action_pressed() -> void:
	if not selected_tower:
		return
	if equipped_towers.has(selected_tower):
		_remove_tower_from_loadout(selected_tower)
	else:
		if equipped_towers.size() < max_loadout_size:
			equipped_towers.append(selected_tower)
			_refresh_all()

func _remove_tower_from_loadout(tower: TowerData) -> void:
	equipped_towers.erase(tower)
	_refresh_all()

func _on_clear_all_pressed() -> void:
	equipped_towers.clear()
	_refresh_all()

func _on_back_pressed() -> void:
	GameManager.load_view(GameManager.View.MAIN_MENU)

func _on_start_battle_pressed() -> void:
	if equipped_towers.is_empty():
		return
	GameManager.selected_loadout = equipped_towers.duplicate()
	GameManager.load_view(GameManager.View.GAME)
