class_name TowerUpgradePopup extends CanvasLayer

var tower_data: TowerData = null

@onready var close_button: Button = %CloseButton
@onready var tower_icon: TextureRect = %TowerIcon
@onready var tower_name_label: Label = %TowerNameLabel
@onready var level_badge_label: Label = %LevelBadgeLabel
@onready var damage_type_badge_label: Label = %DamageTypeBadgeLabel

@onready var stats_comparison_label: Label = %StatsComparisonLabel

@onready var choices_section: VBoxContainer = %ChoicesSectionVBox
@onready var choice_card_a: PanelContainer = %ChoiceCardA
@onready var choice_title_a: Label = %ChoiceTitleA
@onready var choice_type_badge_a: PanelContainer = %ChoiceTypeBadgeA
@onready var choice_type_label_a: Label = %ChoiceTypeLabelA
@onready var choice_desc_a: Label = %ChoiceDescA
@onready var choice_select_btn_a: Button = %ChoiceSelectBtnA

@onready var choice_card_b: PanelContainer = %ChoiceCardB
@onready var choice_title_b: Label = %ChoiceTitleB
@onready var choice_type_badge_b: PanelContainer = %ChoiceTypeBadgeB
@onready var choice_type_label_b: Label = %ChoiceTypeLabelB
@onready var choice_desc_b: Label = %ChoiceDescB
@onready var choice_select_btn_b: Button = %ChoiceSelectBtnB

@onready var upgrade_action_button: Button = %UpgradeActionButton
@onready var credits_balance_label: Label = %CreditsBalanceLabel

func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	choice_select_btn_a.pressed.connect(func(): _on_choice_selected(0))
	choice_select_btn_b.pressed.connect(func(): _on_choice_selected(1))
	upgrade_action_button.pressed.connect(_on_action_button_pressed)
	
	SignalBus.credits_changed.connect(func(_c): _render())
	SignalBus.tower_upgraded.connect(func(_t, _l): _render())
	SignalBus.tower_unlocked.connect(func(_t): _render())
	SignalBus.specialization_unlocked.connect(func(_t, _c): _render())
	SignalBus.tower_choice_changed.connect(func(_t, _c): _render())

func open(p_tower: TowerData) -> void:
	tower_data = p_tower
	show()
	_render()

func close() -> void:
	hide()

func _render() -> void:
	if not tower_data:
		return
	
	var tower_id = Registry.get_tower_id(tower_data)
	var is_unlocked = SaveManager.is_tower_unlocked(tower_id)
	var level = SaveManager.get_tower_level(tower_id) if is_unlocked else 1
	var active_choice = SaveManager.get_tower_choice(tower_id)
	var credits = SaveManager.get_credits()
	
	tower_icon.texture = tower_data.icon
	tower_name_label.text = tower_data.display_name.to_upper()
	credits_balance_label.text = "AVAILABLE: %d CREDITS" % credits
	
	if is_unlocked:
		level_badge_label.get_parent().theme_type_variation = &"StatusBadge"
		level_badge_label.text = "LEVEL %d / %d" % [level, tower_data.max_level]
	else:
		level_badge_label.get_parent().theme_type_variation = &"LockedBadge"
		level_badge_label.text = "LOCKED"
	
	# Current vs Next Stats
	var current_stats = tower_data.get_stat_summary(level, active_choice)
	var next_stats = tower_data.get_stat_summary(min(level + 1, tower_data.max_level), active_choice)
	
	damage_type_badge_label.text = ("%s DAMAGE" % current_stats["damage_type_str"]).to_upper()
	
	var stat_lines: Array[String] = []
	if current_stats["has_attack"]:
		if is_unlocked and level < tower_data.max_level:
			stat_lines.append("Attack Damage: %.0f -> %.0f (+20%%)" % [current_stats["damage"], next_stats["damage"]])
			stat_lines.append("Attack Speed: Every %.2fs -> %.2fs" % [current_stats["cooldown"], next_stats["cooldown"]])
			stat_lines.append("DPS Rating: %.1f -> %.1f" % [current_stats["dps"], next_stats["dps"]])
		else:
			stat_lines.append("Attack Damage: %.0f" % current_stats["damage"])
			stat_lines.append("Attack Speed: Every %.2fs" % current_stats["cooldown"])
			stat_lines.append("DPS Rating: %.1f" % current_stats["dps"])
			
	if current_stats["has_health"]:
		if is_unlocked and level < tower_data.max_level:
			stat_lines.append("Structure Health: %.0f -> %.0f (+25%%)" % [current_stats["max_health"], next_stats["max_health"]])
		else:
			stat_lines.append("Structure Health: %.0f" % current_stats["max_health"])
			
	if current_stats["max_targets"] > 1:
		stat_lines.append("Target Capacity: %d Enemies" % current_stats["max_targets"])
		
	if stat_lines.is_empty():
		stat_lines.append("Defensive Tactical Installation")
		
	stats_comparison_label.text = "\n".join(stat_lines)
	
	# Choices / Specializations
	if tower_data.choices.size() >= 2:
		choices_section.show()
		var choice_a = tower_data.choices[0]
		var choice_b = tower_data.choices[1]
		
		choice_title_a.text = choice_a.title
		choice_desc_a.text = choice_a.description
		
		choice_title_b.text = choice_b.title
		choice_desc_b.text = choice_b.description
		
		_render_choice_card(choice_a, choice_card_a, choice_type_badge_a, choice_type_label_a, choice_select_btn_a, tower_id, level, active_choice, credits, is_unlocked)
		_render_choice_card(choice_b, choice_card_b, choice_type_badge_b, choice_type_label_b, choice_select_btn_b, tower_id, level, active_choice, credits, is_unlocked)
	else:
		choices_section.hide()
		
	# Action button for Base Tower Level
	if not is_unlocked:
		var cost = tower_data.unlock_cost
		if credits >= cost:
			upgrade_action_button.text = "UNLOCK TOWER (%d CREDITS)" % cost
			upgrade_action_button.disabled = false
			upgrade_action_button.theme_type_variation = &"PrimaryButton"
		else:
			upgrade_action_button.text = "INSUFFICIENT CREDITS (%d NEEDED)" % cost
			upgrade_action_button.disabled = true
			upgrade_action_button.theme_type_variation = &"SecondaryButton"
	elif level >= tower_data.max_level:
		upgrade_action_button.text = "MAX LEVEL REACHED"
		upgrade_action_button.disabled = true
		upgrade_action_button.theme_type_variation = &"SecondaryButton"
	else:
		var upgrade_cost = tower_data.get_upgrade_cost(level + 1)
		if credits >= upgrade_cost:
			upgrade_action_button.text = "UPGRADE TO LEVEL %d (%d CREDITS)" % [level + 1, upgrade_cost]
			upgrade_action_button.disabled = false
			upgrade_action_button.theme_type_variation = &"PrimaryButton"
		else:
			upgrade_action_button.text = "UPGRADE TO LV %d (%d CREDITS NEEDED)" % [level + 1, upgrade_cost]
			upgrade_action_button.disabled = true
			upgrade_action_button.theme_type_variation = &"SecondaryButton"

func _render_choice_card(
	choice: TowerChoiceUpgrade,
	card_panel: PanelContainer,
	type_badge: PanelContainer,
	type_label: Label,
	select_btn: Button,
	tower_id: String,
	tower_level: int,
	active_choice: String,
	credits: int,
	is_tower_unlocked: bool
) -> void:
	var req_level = choice.required_level
	var is_level_met = (tower_level >= req_level) and is_tower_unlocked
	var is_bought = SaveManager.is_specialization_unlocked(tower_id, choice.id)
	var is_active = (active_choice == choice.id)
	
	if not is_level_met:
		card_panel.theme_type_variation = &"CardPanel"
		card_panel.self_modulate = Color(0.7, 0.7, 0.7, 0.6)
		type_badge.theme_type_variation = &"LockedBadge"
		type_label.text = "REQUIRES LEVEL %d" % req_level
		select_btn.text = "LOCKED (LV %d REQ)" % req_level
		select_btn.disabled = true
		select_btn.theme_type_variation = &"SecondaryButton"
	elif not is_bought:
		card_panel.theme_type_variation = &"CardPanel"
		card_panel.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		type_badge.theme_type_variation = &"TypeBadge"
		type_label.text = _get_damage_type_label(choice)
		if credits >= choice.unlock_cost:
			select_btn.text = "UNLOCK (%d CREDITS)" % choice.unlock_cost
			select_btn.disabled = false
			select_btn.theme_type_variation = &"PrimaryButton"
		else:
			select_btn.text = "UNLOCK (%d CREDITS)" % choice.unlock_cost
			select_btn.disabled = true
			select_btn.theme_type_variation = &"SecondaryButton"
	else:
		# Unlocked / Purchased
		card_panel.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		type_badge.theme_type_variation = &"TypeBadge"
		type_label.text = _get_damage_type_label(choice)
		if is_active:
			card_panel.theme_type_variation = &"CardSelectedPanel"
			select_btn.text = "ACTIVE (CLICK TO REMOVE)"
			select_btn.disabled = false
			select_btn.theme_type_variation = &"PrimaryButton"
		else:
			card_panel.theme_type_variation = &"CardPanel"
			select_btn.text = "ACTIVATE"
			select_btn.disabled = false
			select_btn.theme_type_variation = &"SecondaryButton"

func _get_damage_type_label(choice: TowerChoiceUpgrade) -> String:
	if choice.has_damage_type_override:
		match choice.damage_type_override:
			AttackComponent.DamageType.PHYSICAL: return "PHYSICAL DAMAGE"
			AttackComponent.DamageType.MAGIC: return "MAGIC DAMAGE"
			AttackComponent.DamageType.TRUE: return "TRUE DAMAGE"
	return "SPECIALIZATION"

func _on_choice_selected(index: int) -> void:
	if not tower_data or index >= tower_data.choices.size():
		return
	var tower_id = Registry.get_tower_id(tower_data)
	if not SaveManager.is_tower_unlocked(tower_id):
		return
		
	var level = SaveManager.get_tower_level(tower_id)
	var chosen = tower_data.choices[index]
	
	if level < chosen.required_level:
		return
		
	var is_bought = SaveManager.is_specialization_unlocked(tower_id, chosen.id)
	if not is_bought:
		var unlocked = SaveManager.unlock_specialization(tower_id, chosen.id, chosen.unlock_cost)
		if unlocked:
			_render()
	else:
		var current_choice = SaveManager.get_tower_choice(tower_id)
		if current_choice == chosen.id:
			# Toggle off / reset to base
			SaveManager.set_tower_choice(tower_id, "")
		else:
			SaveManager.set_tower_choice(tower_id, chosen.id)
		_render()

func _on_action_button_pressed() -> void:
	if not tower_data:
		return
	var tower_id = Registry.get_tower_id(tower_data)
	var is_unlocked = SaveManager.is_tower_unlocked(tower_id)
	
	if not is_unlocked:
		var unlock_success = SaveManager.unlock_tower(tower_id, tower_data.unlock_cost)
		if unlock_success:
			_render()
	else:
		var level = SaveManager.get_tower_level(tower_id)
		if level < tower_data.max_level:
			var cost = tower_data.get_upgrade_cost(level + 1)
			var up_success = SaveManager.upgrade_tower(tower_id, cost)
			if up_success:
				_render()
