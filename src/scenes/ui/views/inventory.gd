class_name InventoryView extends MarginContainer

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_cost: Label = %DetailCost
@onready var detail_level_badge: Label = %DetailLevelBadge
@onready var detail_type_badge: Label = %DetailTypeBadge
@onready var detail_desc: Label = %DetailDesc
@onready var detail_stats_grid: GridContainer = %DetailStatsGrid
@onready var detail_trait_label: Label = %DetailTraitLabel
@onready var upgrade_button: Button = %UpgradeButton
@onready var add_credits_button: Button = %AddCreditsButton
@onready var respec_arsenal_button: Button = %RespecArsenalButton
@onready var tower_upgrade_popup: TowerUpgradePopup = %TowerUpgradePopup

var _cards: Array[Card] = []
var _selected_tower: TowerData = null
var _countdown_accum: float = 0.0

func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	if add_credits_button:
		add_credits_button.pressed.connect(_on_add_credits_pressed)
	if respec_arsenal_button:
		respec_arsenal_button.pressed.connect(_on_respec_arsenal_pressed)
	
	SignalBus.credits_changed.connect(func(_c): _refresh_all())
	SignalBus.tower_unlocked.connect(func(_t): _refresh_all())
	SignalBus.tower_upgraded.connect(func(_t, _l): _refresh_all())
	SignalBus.tower_choice_changed.connect(func(_t, _c): _refresh_all())
	
	AdManager.ads_enabled_changed.connect(func(_e): _update_action_buttons())
	
	_update_action_buttons()
	_populate_towers()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if AdManager.is_paid_version() and add_credits_button:
		_countdown_accum += delta
		if _countdown_accum >= 1.0:
			_countdown_accum = 0.0
			_update_action_buttons()

func _refresh_all() -> void:
	_update_action_buttons()
	_populate_towers()
	if _selected_tower:
		_update_details(_selected_tower)

func _update_action_buttons() -> void:
	if add_credits_button:
		add_credits_button.visible = true
		if AdManager.is_paid_version():
			if SaveManager.can_claim_free_credits():
				add_credits_button.text = "CLAIM FREE CREDITS (+%d)" % SaveManager.FREE_CREDITS_CLAIM_AMOUNT
				add_credits_button.disabled = false
				add_credits_button.theme_type_variation = &"PrimaryButton"
			else:
				var rem = SaveManager.get_free_credits_cooldown_remaining()
				var hours = rem / 3600
				var mins = (rem % 3600) / 60
				var secs = rem % 60
				if hours > 0:
					add_credits_button.text = "CLAIM IN %dh %02dm" % [hours, mins]
				else:
					add_credits_button.text = "CLAIM IN %02dm %02ds" % [mins, secs]
				add_credits_button.disabled = true
				add_credits_button.theme_type_variation = &"SecondaryButton"
		else:
			add_credits_button.text = "+100 CREDITS (AD)"
			add_credits_button.disabled = false
			add_credits_button.theme_type_variation = &"PrimaryButton"
	
	if respec_arsenal_button:
		var total_spent := SaveManager.get_total_spent_credits()
		respec_arsenal_button.visible = (total_spent > 0)
		respec_arsenal_button.text = "RESET ARSENAL"

func _populate_towers() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_cards.clear()

	var all_towers = Registry.get_all_towers_sorted()
	for tower in all_towers:
		var card = CARD_SCENE.instantiate() as Card
		grid_container.add_child(card)
		
		var t_id = Registry.get_tower_id(tower)
		var is_unlocked = SaveManager.is_tower_unlocked(t_id)
		var is_avail = tower.is_available()
		var badge = ""
		if is_unlocked:
			badge = "LV %d" % SaveManager.get_tower_level(t_id)
		elif not is_avail:
			badge = "UNAVAILABLE"
		else:
			badge = "LOCKED"
		
		card.setup(tower.icon, tower.display_name, badge, tower, not is_unlocked, not is_unlocked and not is_avail)
		card.card_clicked.connect(_on_card_clicked)
		_cards.append(card)
		
	if all_towers.size() > 0:
		if not _selected_tower or not all_towers.has(_selected_tower):
			_select_tower(all_towers[0])
		else:
			_select_tower(_selected_tower)

func _on_card_clicked(card: Card) -> void:
	if card.data is TowerData:
		_select_tower(card.data)

func _select_tower(tower: TowerData) -> void:
	_selected_tower = tower
	
	for card in _cards:
		card.set_card_selected(card.data == tower)
		
	_update_details(tower)

func _update_details(tower: TowerData) -> void:
	if not tower:
		return
		
	var t_id = Registry.get_tower_id(tower)
	var is_unlocked = SaveManager.is_tower_unlocked(t_id)
	var is_avail = tower.is_available()
	var level = SaveManager.get_tower_level(t_id) if is_unlocked else 1
	var active_choice = SaveManager.get_tower_choice(t_id)
	var stats = tower.get_stats(level, active_choice)
	
	detail_icon.texture = tower.icon
	detail_title.text = tower.display_name
	detail_cost.text = "%d Energy" % tower.cost
	
	if is_unlocked:
		detail_icon.modulate = Color.WHITE
		detail_level_badge.get_parent().theme_type_variation = &"StatusBadge"
		detail_level_badge.text = "LEVEL %d / %d" % [level, tower.max_level]
		upgrade_button.text = "UPGRADE & SPECIALIZE"
		upgrade_button.disabled = false
		upgrade_button.theme_type_variation = &"PrimaryButton"
	elif not is_avail:
		detail_icon.modulate = Color(0.35, 0.38, 0.45, 0.50)
		detail_level_badge.get_parent().theme_type_variation = &"UnavailableBadge"
		detail_level_badge.text = "UNAVAILABLE"
		var req_desc = tower.get_requirement_description()
		if not req_desc.is_empty():
			upgrade_button.text = "LOCKED (%s)" % req_desc.to_upper()
		else:
			upgrade_button.text = "UNAVAILABLE (STAGE LOCKED)"
		upgrade_button.disabled = true
		upgrade_button.theme_type_variation = &"SecondaryButton"
	else:
		detail_icon.modulate = Color(0.45, 0.48, 0.55, 0.70)
		detail_level_badge.get_parent().theme_type_variation = &"LockedBadge"
		detail_level_badge.text = "LOCKED"
		var credits = SaveManager.get_credits()
		upgrade_button.text = "UNLOCK (%d CREDITS)" % tower.unlock_cost
		if credits >= tower.unlock_cost:
			upgrade_button.disabled = false
			upgrade_button.theme_type_variation = &"PrimaryButton"
		else:
			upgrade_button.disabled = true
			upgrade_button.theme_type_variation = &"SecondaryButton"
		
	detail_type_badge.text = (stats.get("type", "DEFENSE")).to_upper()
	
	var base_desc = tower.description if not tower.description.is_empty() else "Standard defensive installation."
	if not is_unlocked and not is_avail:
		var req_desc = tower.get_requirement_description()
		detail_desc.text = "%s  [%s]" % [base_desc, req_desc] if not req_desc.is_empty() else base_desc
	else:
		detail_desc.text = base_desc
	
	for child in detail_stats_grid.get_children():
		child.queue_free()
		
	var grid_stats: Array = stats.get("grid_stats", [])
	for item in grid_stats:
		if item is Dictionary:
			var card = _create_stat_card(item.get("label", ""), item.get("value", ""))
			detail_stats_grid.add_child(card)
		elif item is String:
			var parts = item.split(":", true, 1)
			var key = parts[0].strip_edges() if parts.size() > 1 else "STAT"
			var val = parts[1].strip_edges() if parts.size() > 1 else item
			var card = _create_stat_card(key, val)
			detail_stats_grid.add_child(card)
			
	var traits: Array = stats.get("traits", [])
	if traits.is_empty():
		detail_trait_label.text = ""
		detail_trait_label.visible = false
	else:
		detail_trait_label.text = " • ".join(traits)
		detail_trait_label.visible = true

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

func _on_upgrade_button_pressed() -> void:
	if not _selected_tower:
		return
	var t_id = Registry.get_tower_id(_selected_tower)
	var is_unlocked = SaveManager.is_tower_unlocked(t_id)
	if not is_unlocked and not _selected_tower.is_available():
		return
	if tower_upgrade_popup:
		tower_upgrade_popup.open(_selected_tower)

func _on_add_credits_pressed() -> void:
	if AdManager.is_paid_version():
		if SaveManager.can_claim_free_credits():
			SaveManager.claim_free_credits()
			_update_action_buttons()
	else:
		AdManager.show_rewarded()

func _on_respec_arsenal_pressed() -> void:
	var popup_scene = load("res://src/scenes/ui/popups/respec_popup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		get_tree().root.add_child(popup)
		popup.respec_completed.connect(func(_amt): _refresh_all())
		popup.open_for_all()
