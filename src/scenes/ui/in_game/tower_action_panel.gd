class_name TowerActionPanel extends PanelContainer

@onready var icon_rect: TextureRect = %IconRect
@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var sell_button: Button = %SellButton
@onready var close_button: Button = %CloseButton

var _current_tower: Tower = null

func _ready() -> void:
	hide()
	
	sell_button.focus_mode = Control.FOCUS_NONE
	close_button.focus_mode = Control.FOCUS_NONE
	
	sell_button.pressed.connect(_on_sell_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	SignalBus.tower_selected.connect(_on_tower_selected)
	SignalBus.tower_deselected.connect(_on_tower_deselected)
	SignalBus.placement_mode_changed.connect(_on_placement_mode_changed)

func open(tower: Tower) -> void:
	if not is_instance_valid(tower) or not tower.data:
		close()
		return
	
	_current_tower = tower
	_update_ui()
	show()

func close() -> void:
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
	
	if stats_label:
		var stat_lines: Array[String] = []
		
		var attack_data: AttackData = null
		if _current_tower.attack and _current_tower.attack.data:
			attack_data = _current_tower.attack.data
		elif data.attack:
			attack_data = data.attack
			
		if attack_data:
			var dps: float = attack_data.damage / maxf(attack_data.cooldown, 0.05)
			stat_lines.append("DMG: %.0f   SPD: %.2fs   DPS: %.1f" % [attack_data.damage, attack_data.cooldown, dps])
		
		var effect_data: EffectApplierData = null
		if _current_tower.effect_applier and _current_tower.effect_applier.data:
			effect_data = _current_tower.effect_applier.data
		elif data.effect_applier:
			effect_data = data.effect_applier
			
		if effect_data:
			var cd_str: String = "%.1fs" % effect_data.cooldown if effect_data.cooldown > 0.0 else "Continuous"
			stat_lines.append("TRAP COOLDOWN: %s" % cd_str)
		
		if _current_tower.health and _current_tower.health.data:
			var current_hp: float = _current_tower.health.get_health()
			var max_hp: float = _current_tower.health.data.max_health
			stat_lines.append("HEALTH: %d / %d" % [int(current_hp), int(max_hp)])
		elif data.health:
			stat_lines.append("HEALTH: %d / %d" % [int(data.health.max_health), int(data.health.max_health)])
		elif data.is_solid:
			stat_lines.append("TYPE: SOLID DEFENSE")
		
		stats_label.text = "\n".join(stat_lines)

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

func _on_tower_selected(tower: Tower) -> void:
	open(tower)

func _on_tower_deselected() -> void:
	close()

func _on_placement_mode_changed(is_active: bool) -> void:
	if is_active:
		close()
