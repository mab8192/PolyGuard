class_name TowerActionPanel extends PanelContainer

@onready var icon_rect: TextureRect = %IconRect
@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var strategy_row: HBoxContainer = %StrategyRow
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
	
	if _current_tower and is_instance_valid(_current_tower) and _current_tower.health:
		if _current_tower.health.health_changed.is_connected(_on_tower_health_changed):
			_current_tower.health.health_changed.disconnect(_on_tower_health_changed)

	_current_tower = tower
	if _current_tower and _current_tower.health:
		_current_tower.health.health_changed.connect(_on_tower_health_changed)

	_update_ui()
	show()

func close() -> void:
	if _current_tower and is_instance_valid(_current_tower) and _current_tower.health:
		if _current_tower.health.health_changed.is_connected(_on_tower_health_changed):
			_current_tower.health.health_changed.disconnect(_on_tower_health_changed)
	_current_tower = null
	hide()

func _update_ui() -> void:
	if not _current_tower or not is_instance_valid(_current_tower) or not _current_tower.data:
		return
	
	var data: TowerData = _current_tower.data
	if icon_rect:
		icon_rect.texture = data.icon
	
	if title_label:
		title_label.text = data.display_name.to_upper()
	
	var sell_amount: int = _current_tower.get_sell_value()
	if sell_button:
		sell_button.text = "SELL +%d ENERGY" % sell_amount
	
	# Rich stats display
	if stats_label:
		var stats = _current_tower.get_stats()
		var lines: Array[String] = stats.get("runtime_lines", [])
		if lines.is_empty():
			lines = stats.get("stat_lines", [])
		stats_label.text = "\n".join(lines)
	
	# Targeting Strategy Row
	if _current_tower.targeting and _current_tower.targeting.data:
		strategy_row.show()
		var strat_name = _current_tower.targeting.get_strategy_name()
		strategy_button.text = "TARGET: %s 🔄" % strat_name
	else:
		strategy_row.hide()
	
	# Repair Button
	if _current_tower.health and _current_tower.health.data and _current_tower.collision_layer > 0:
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

func _on_strategy_pressed() -> void:
	if _current_tower and is_instance_valid(_current_tower) and _current_tower.targeting:
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
