class_name TowerActionPanel extends PanelContainer

@onready var icon_rect: TextureRect = %IconRect
@onready var title_label: Label = %TitleLabel
@onready var stats_grid: HBoxContainer = %StatsGrid
@onready var left_column: VBoxContainer = %LeftColumn
@onready var strategy_button: Button = %StrategyButton
@onready var repair_button: Button = %RepairButton
@onready var sell_button: Button = %SellButton
@onready var close_button: Button = %CloseButton

var _current_tower: Tower = null

func _ready() -> void:
	hide()
	
	sell_button.focus_mode = Control.FOCUS_NONE
	repair_button.focus_mode = Control.FOCUS_NONE
	strategy_button.focus_mode = Control.FOCUS_NONE
	close_button.focus_mode = Control.FOCUS_NONE
	
	sell_button.pressed.connect(_on_sell_pressed)
	repair_button.pressed.connect(_on_repair_pressed)
	strategy_button.pressed.connect(_on_strategy_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	SignalBus.tower_selected.connect(_on_tower_selected)
	SignalBus.tower_deselected.connect(_on_tower_deselected)
	SignalBus.placement_mode_changed.connect(_on_placement_mode_changed)
	SignalBus.energy_changed.connect(_on_energy_changed)

func open(tower: Tower) -> void:
	if not is_instance_valid(tower) or not tower.data:
		close()
		return
	
	if is_instance_valid(_current_tower) and _current_tower.health:
		if _current_tower.health.health_changed.is_connected(_on_tower_health_changed):
			_current_tower.health.health_changed.disconnect(_on_tower_health_changed)

	_current_tower = tower
	if _current_tower.health:
		_current_tower.health.health_changed.connect(_on_tower_health_changed)

	_update_ui()
	show()

func close() -> void:
	if is_instance_valid(_current_tower) and _current_tower.health:
		if _current_tower.health.health_changed.is_connected(_on_tower_health_changed):
			_current_tower.health.health_changed.disconnect(_on_tower_health_changed)
	_current_tower = null
	hide()

func _update_ui() -> void:
	if not is_instance_valid(_current_tower) or not _current_tower.data:
		return
	
	var data: TowerData = _current_tower.data
	if icon_rect:
		icon_rect.texture = data.icon
	
	if title_label:
		title_label.text = data.display_name.to_upper()
	
	var sell_amount: int = _current_tower.get_sell_value()
	if sell_button:
		sell_button.text = "SELL +%d ENERGY" % sell_amount
	
	# Populate single row with the top 3 priority stat cards
	if stats_grid:
		for child in stats_grid.get_children():
			child.queue_free()
		
		var stats = _current_tower.get_stats()
		var top_stats = _get_top_3_stats(stats, _current_tower)
		
		for item in top_stats:
			var key: String = item.get("label", "")
			var val: String = item.get("value", "")
			var card = _create_stat_card(key, val)
			stats_grid.add_child(card)
	
	# Targeting Strategy Row / Button
	var has_strategy = (_current_tower.targeting != null and _current_tower.targeting.data != null)
	if has_strategy:
		strategy_button.show()
		var strat_name = _current_tower.targeting.get_strategy_name()
		strategy_button.text = "TARGET: %s" % strat_name.to_upper()
	else:
		strategy_button.hide()
	
	# Repair Button
	var has_repair = (_current_tower.health != null and _current_tower.health.data != null and _current_tower.collision_layer > 0)
	if has_repair:
		repair_button.show()
		var cost = _current_tower.get_repair_cost()
		if cost > 0:
			repair_button.text = "REPAIR (%d ENERGY)" % cost
			var current_energy = GameManager.current_stage.energy if GameManager.current_stage else 0
			repair_button.disabled = (current_energy < cost)
		else:
			repair_button.text = "FULL HEALTH"
			repair_button.disabled = true
	else:
		repair_button.hide()
	
	if left_column:
		left_column.visible = (has_strategy or has_repair)

func _get_top_3_stats(stats: Dictionary, tower: Tower) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var t_id = Registry.get_tower_id(tower.data) if tower.data else ""
	var choice_id = SaveManager.get_tower_choice(t_id) if not t_id.is_empty() else ""
	var level = SaveManager.get_tower_level(t_id) if (not t_id.is_empty() and SaveManager.is_tower_unlocked(t_id)) else 1
	var summary = tower.data.get_stat_summary(level, choice_id) if tower.data else {}
	
	# 1. HP (Structure/Wall/Damageable towers)
	var has_health: bool = (tower.health != null and tower.health.data != null and tower.collision_layer > 0)
	if has_health:
		var cur_hp: int = int(ceil(tower.health.get_health()))
		var max_hp: int = int(tower.health.get_max_health())
		result.append({"label": "HP", "value": "%d / %d" % [cur_hp, max_hp]})
	
	# 2. Primary Combat / Offensive Output
	if stats.get("has_attack", false) and stats.get("damage", 0.0) > 0.0:
		var dmg_type = stats.get("damage_type_str", "Normal").left(4) if stats.get("damage_type_str", "") != "Normal" else ""
		var dmg_val = "%.0f (%s)" % [stats.get("damage", 0.0), dmg_type] if not dmg_type.is_empty() else "%.0f" % stats.get("damage", 0.0)
		result.append({"label": "DAMAGE", "value": dmg_val})
	elif stats.get("dot_dps", 0.0) > 0.0:
		result.append({"label": "DoT", "value": "%.0f/s" % stats.get("dot_dps", 0.0)})
	elif summary.get("has_freeze", false):
		result.append({"label": "FREEZE", "value": "%.1fs" % summary.get("freeze_duration", 0.0)})
	elif summary.get("slow_pct", 0.0) > 0.0:
		result.append({"label": "SLOW", "value": "-%.0f%%" % summary.get("slow_pct", 0.0)})
	elif summary.get("armor_reduction", 0.0) > 0.0:
		result.append({"label": "ARMOR", "value": "-%.0f" % summary.get("armor_reduction", 0.0)})
	elif summary.get("magic_resistance_reduction", 0.0) > 0.0:
		result.append({"label": "MAGIC RES", "value": "-%.0f" % summary.get("magic_resistance_reduction", 0.0)})
	elif summary.get("energy_reward_bonus", 0.0) > 0.0:
		result.append({"label": "ENERGY", "value": "+%.0f%%" % summary.get("energy_reward_bonus", 0.0)})

	# 3. Fire Rate / Speed / Cycle
	if stats.get("cooldown", 0.0) > 0.0:
		var cd_label = "RATE" if stats.get("has_attack", false) else "CYCLE"
		result.append({"label": cd_label, "value": "%.2fs" % stats.get("cooldown", 0.0)})
	elif stats.get("has_attack", false) and stats.get("cooldown", 0.0) <= 0.0:
		result.append({"label": "RATE", "value": "Cont."})

	# 4. DPS
	if stats.get("dps", 0.0) > 0.0:
		result.append({"label": "DPS", "value": "%.1f" % stats.get("dps", 0.0)})

	# 5. Capacity / Targets
	if stats.get("max_targets", 1) > 1:
		result.append({"label": "TARGETS", "value": "%d Units" % stats.get("max_targets", 1)})

	# 6. Fallback traits
	if summary.get("targets_ghosts", false):
		result.append({"label": "GHOSTS", "value": "Detect"})
	elif summary.get("blocks_ghosts", false):
		result.append({"label": "BARRIER", "value": "Active"})

	# Deduplicate and cap to top 3
	var top3: Array[Dictionary] = []
	var seen_labels = {}
	for item in result:
		var lbl = item.get("label", "")
		if not seen_labels.has(lbl):
			seen_labels[lbl] = true
			top3.append(item)
			if top3.size() == 3:
				break

	return top3

func _create_stat_card(key_text: String, value_text: String) -> PanelContainer:
	var card = PanelContainer.new()
	card.theme_type_variation = &"StatCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	var lbl_key = Label.new()
	lbl_key.theme_type_variation = &"StatKeyText"
	lbl_key.text = key_text
	lbl_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_key)
	
	var lbl_val = Label.new()
	lbl_val.theme_type_variation = &"StatValueText"
	lbl_val.text = value_text
	lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_val)
	
	return card

func _on_strategy_pressed() -> void:
	if is_instance_valid(_current_tower) and _current_tower.targeting:
		_current_tower.targeting.cycle_strategy(true)
		_update_ui()

func _on_repair_pressed() -> void:
	if GameManager.current_stage:
		var success = GameManager.current_stage.repair_selected_tower()
		if success:
			_update_ui()
	else:
		close()

func _on_sell_pressed() -> void:
	if GameManager.current_stage:
		GameManager.current_stage.sell_selected_tower()
	else:
		close()

func _on_close_pressed() -> void:
	if GameManager.current_stage:
		GameManager.current_stage.deselect_tower()
	else:
		close()

func _on_tower_health_changed(_hp: float) -> void:
	if visible and is_instance_valid(_current_tower):
		_update_ui()

func _on_energy_changed(_energy: int) -> void:
	if visible and is_instance_valid(_current_tower):
		_update_ui()

func _on_tower_selected(tower: Tower) -> void:
	open(tower)

func _on_tower_deselected() -> void:
	close()

func _on_placement_mode_changed(is_active: bool) -> void:
	if is_active:
		close()
