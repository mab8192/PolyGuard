class_name TowerUpgradePopup extends CanvasLayer

var tower_data: TowerData = null

@onready var center_container: CenterContainer = %CenterContainer
@onready var close_button: Button = %CloseButton
@onready var tower_icon: TextureRect = %TowerIcon
@onready var tower_name_label: Label = %TowerNameLabel
@onready var level_badge_label: Label = %LevelBadgeLabel
@onready var damage_type_badge_label: Label = %DamageTypeBadgeLabel

@onready var stats_comparison_label: Label = %StatsComparisonLabel

@onready var choices_section: VBoxContainer = %ChoicesSectionVBox
@onready var choice_card_a: PanelContainer = %ChoiceCardA
@onready var choice_icon_a: TextureRect = %ChoiceIconA
@onready var choice_title_a: Label = %ChoiceTitleA
@onready var choice_desc_a: Label = %ChoiceDescA
@onready var choice_details_label_a: Label = %ChoiceDetailsLabelA
@onready var choice_select_btn_a: Button = %ChoiceSelectBtnA

@onready var choice_card_b: PanelContainer = %ChoiceCardB
@onready var choice_icon_b: TextureRect = %ChoiceIconB
@onready var choice_title_b: Label = %ChoiceTitleB
@onready var choice_desc_b: Label = %ChoiceDescB
@onready var choice_details_label_b: Label = %ChoiceDetailsLabelB
@onready var choice_select_btn_b: Button = %ChoiceSelectBtnB

@onready var upgrade_action_button: Button = %UpgradeActionButton
@onready var credits_balance_label: Label = %CreditsBalanceLabel

func _ready() -> void:
	hide()
	add_to_group(GameManager.BACK_CLOSABLE_GROUP)

	center_container.gui_input.connect(_on_background_click)
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

func _on_background_click(event: InputEvent) -> void:
	if event.is_pressed():
		close()

func _render() -> void:
	if not tower_data:
		return
	
	var tower_id = Registry.get_tower_id(tower_data)
	var is_unlocked = SaveManager.is_tower_unlocked(tower_id)
	var level = SaveManager.get_tower_level(tower_id) if is_unlocked else 1
	var active_choice = SaveManager.get_tower_choice(tower_id)
	var credits = SaveManager.get_credits()
	
	tower_name_label.text = tower_data.display_name.to_upper()
	credits_balance_label.text = "AVAILABLE: %d CREDITS" % credits
	
	var is_avail = tower_data.is_available()
	
	if is_unlocked:
		level_badge_label.get_parent().theme_type_variation = &"StatusBadge"
		level_badge_label.text = "LEVEL %d / %d" % [level, tower_data.max_level]
	elif not is_avail:
		level_badge_label.get_parent().theme_type_variation = &"UnavailableBadge"
		level_badge_label.text = "UNAVAILABLE"
	else:
		level_badge_label.get_parent().theme_type_variation = &"LockedBadge"
		level_badge_label.text = "LOCKED"
	
	# Current vs Next Stats
	var current_stats = tower_data.get_stat_summary(level, active_choice)
	var next_stats = tower_data.get_stat_summary(min(level + 1, tower_data.max_level), active_choice)
	
	tower_icon.texture = current_stats.get("icon", tower_data.icon)
	damage_type_badge_label.text = ("%s DAMAGE" % current_stats["damage_type_str"]).to_upper()
	
	var stat_lines: Array[String] = []
	var is_upgradable: bool = is_unlocked and level < tower_data.max_level
	var dmg_pct = tower_data.damage_upgrade_per_level * 100.0
	var cd_pct = tower_data.cooldown_reduction_per_level * 100.0

	# 1. Direct / Initial Attack Damage
	if current_stats["damage"] > 0.0:
		var dmg_label = "Initial Damage" if current_stats["has_dot"] else "Attack Damage"
		if is_upgradable:
			stat_lines.append("%s: %.0f -> %.0f (+%.0f%%)" % [dmg_label, current_stats["damage"], next_stats["damage"], dmg_pct])
		else:
			stat_lines.append("%s: %.0f" % [dmg_label, current_stats["damage"]])

	# 2. DoT Damage & Duration
	if current_stats["dot_dps"] > 0.0:
		if is_upgradable:
			stat_lines.append("Damage Over Time: %.0f/s -> %.0f/s (+%.0f%%)" % [current_stats["dot_dps"], next_stats["dot_dps"], dmg_pct])
		else:
			stat_lines.append("Damage Over Time: %.0f/s" % current_stats["dot_dps"])
		if current_stats["dot_duration"] > 0.0:
			stat_lines.append("DoT Duration: %.1fs" % current_stats["dot_duration"])

	# 3. Fire Rate / Trigger Cycle
	if current_stats["cooldown"] > 0.0:
		var is_trap_applier = tower_data.effect_applier != null
		var cd_label = "Trigger Cooldown" if is_trap_applier else "Attack Speed"
		if is_upgradable:
			stat_lines.append("%s: Every %.2fs -> %.2fs (-%.0f%% cd)" % [cd_label, current_stats["cooldown"], next_stats["cooldown"], cd_pct])
		else:
			stat_lines.append("%s: Every %.2fs" % [cd_label, current_stats["cooldown"]])

	# 4. DPS Rating
	if current_stats["dps"] > 0.0:
		if is_upgradable:
			stat_lines.append("DPS Rating: %.1f -> %.1f" % [current_stats["dps"], next_stats["dps"]])
		else:
			stat_lines.append("DPS Rating: %.1f" % current_stats["dps"])

	# 5. Active Duration
	if current_stats["active_duration"] > 0.0:
		stat_lines.append("Active Duration: %.1fs" % current_stats["active_duration"])

	# 6. Status Effects
	if current_stats["slow_pct"] > 0.0:
		stat_lines.append("Movement Slow: -%.0f%%" % current_stats["slow_pct"])
	if current_stats["has_freeze"]:
		stat_lines.append("Freeze Duration: %.1fs" % current_stats["freeze_duration"])
	if current_stats["armor_reduction"] > 0.0:
		stat_lines.append("Armor Shred: -%.0f" % current_stats["armor_reduction"])
	if current_stats["magic_resistance_reduction"] > 0.0:
		stat_lines.append("Magic Resistance Shred: -%.0f" % current_stats["magic_resistance_reduction"])
	if current_stats["energy_reward_bonus"] > 0.0:
		stat_lines.append("Energy Reward Bonus: +%.0f%%" % current_stats["energy_reward_bonus"])
			
	if current_stats["has_health"]:
		if is_upgradable:
			var hp_pct = tower_data.health_upgrade_per_level * 100.0
			stat_lines.append("Structure Health: %.0f -> %.0f (+%.0f%%)" % [current_stats["max_health"], next_stats["max_health"], hp_pct])
		else:
			stat_lines.append("Structure Health: %.0f" % current_stats["max_health"])
			
	if current_stats["max_targets"] > 1:
		stat_lines.append("Target Capacity: %d Enemies" % current_stats["max_targets"])
		
	if current_stats["targets_ghosts"]:
		stat_lines.append("Ghost Detection: ENABLED")
	if current_stats["blocks_ghosts"]:
		stat_lines.append("Ghost Barrier: ACTIVE (Blocks Ghosts)")
	
	# Tower specific lines
	if tower_data.tower_id == "soul_lantern":
		stat_lines.append("Trait: Ramping Focus Damage (+35%/s)")
	elif tower_data.tower_id == "tesla_tower":
		stat_lines.append("Trait: Arc Lightning Chain")
	elif tower_data.tower_id == "flamethrower":
		stat_lines.append("Trait: Continuous Thermal Cone")
	elif tower_data.tower_id == "tar_trap":
		stat_lines.append("Effect: Reduces Enemy Movement Speed by 50%")
	elif tower_data.tower_id == "wind_wall":
		stat_lines.append("Trait: Continuous & Burst Wind Pushback (Physics Force)")
	elif tower_data.tower_id == "acid_wall":
		stat_lines.append("Trait: Directional Caustic Spray (-25 Armor & DoT)")
	elif tower_data.tower_id == "siphon":
		stat_lines.append("Effect: Increases Enemy Energy Reward by 50%")
		
	if not active_choice.is_empty():
		var active_spec = tower_data.get_choice(active_choice)
		if active_spec:
			stat_lines.append("Active Specialization: %s" % active_spec.title)

	if stat_lines.is_empty():
		stat_lines.append("No stats available")
		
	stats_comparison_label.text = "\n".join(stat_lines)
	
	# Choices / Specializations
	if tower_data.choices.size() >= 2:
		choices_section.show()
		var choice_a = tower_data.choices[0]
		var choice_b = tower_data.choices[1]
		
		choice_title_a.text = choice_a.title
		choice_title_b.text = choice_b.title
		
		_render_choice_card(choice_a, choice_card_a, choice_icon_a, choice_desc_a, choice_details_label_a, choice_select_btn_a, tower_id, level, active_choice, credits, is_unlocked)
		_render_choice_card(choice_b, choice_card_b, choice_icon_b, choice_desc_b, choice_details_label_b, choice_select_btn_b, tower_id, level, active_choice, credits, is_unlocked)
	else:
		choices_section.hide()
		
	# Action button for Base Tower Level
	if not is_unlocked:
		if not is_avail:
			var req_desc = tower_data.get_requirement_description()
			if not req_desc.is_empty():
				upgrade_action_button.text = "LOCKED (%s)" % req_desc.to_upper()
			else:
				upgrade_action_button.text = "UNAVAILABLE (STAGE LOCKED)"
			upgrade_action_button.disabled = true
			upgrade_action_button.theme_type_variation = &"SecondaryButton"
		else:
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
	icon_rect: TextureRect,
	desc_label: Label,
	details_label: Label,
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
	
	if icon_rect:
		icon_rect.texture = choice.icon if choice.icon else tower_data.icon
	
	if desc_label:
		desc_label.text = choice.description
		
	if details_label:
		var details = choice.get_upgrade_details()
		if not details.is_empty():
			details_label.text = "• " + "\n• ".join(details)
			details_label.show()
		else:
			details_label.hide()

	if not is_level_met:
		card_panel.theme_type_variation = &"CardPanel"
		card_panel.self_modulate = Color(0.7, 0.7, 0.7, 0.6)
		select_btn.text = "LOCKED (LV %d REQ)" % req_level
		select_btn.disabled = true
		select_btn.theme_type_variation = &"SecondaryButton"
	elif not is_bought:
		card_panel.theme_type_variation = &"CardPanel"
		card_panel.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
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
		if is_active:
			card_panel.theme_type_variation = &"CardSelectedPanel"
			select_btn.text = "DEACTIVATE"
			select_btn.disabled = false
			select_btn.theme_type_variation = &"PrimaryButton"
		else:
			card_panel.theme_type_variation = &"CardPanel"
			select_btn.text = "ACTIVATE"
			select_btn.disabled = false
			select_btn.theme_type_variation = &"SecondaryButton"

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
		if not tower_data.is_available():
			return
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
