class_name InventoryView extends MarginContainer

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_cost: Label = %DetailCost
@onready var detail_level_badge: Label = %DetailLevelBadge
@onready var detail_type_badge: Label = %DetailTypeBadge
@onready var detail_desc: Label = %DetailDesc
@onready var detail_stats: Label = %DetailStats
@onready var upgrade_button: Button = %UpgradeButton
@onready var tower_upgrade_popup: TowerUpgradePopup = %TowerUpgradePopup

var _cards: Array[Card] = []
var _selected_tower: TowerData = null

func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	
	SignalBus.credits_changed.connect(func(_c): _refresh_all())
	SignalBus.tower_unlocked.connect(func(_t): _refresh_all())
	SignalBus.tower_upgraded.connect(func(_t, _l): _refresh_all())
	SignalBus.tower_choice_changed.connect(func(_t, _c): _refresh_all())
	
	_populate_towers()

func _refresh_all() -> void:
	_populate_towers()
	if _selected_tower:
		_update_details(_selected_tower)

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
		var badge = ("LV %d" % SaveManager.get_tower_level(t_id)) if is_unlocked else "LOCKED"
		
		card.setup(tower.icon, tower.display_name, badge, tower, not is_unlocked)
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
	var level = SaveManager.get_tower_level(t_id) if is_unlocked else 1
	var active_choice = SaveManager.get_tower_choice(t_id)
	var stats = tower.get_stat_summary(level, active_choice)
	
	detail_icon.texture = tower.icon
	detail_title.text = tower.display_name
	detail_cost.text = "%d Energy" % tower.cost
	
	if is_unlocked:
		detail_icon.modulate = Color.WHITE
		detail_level_badge.get_parent().theme_type_variation = &"StatusBadge"
		detail_level_badge.text = "LEVEL %d / %d" % [level, tower.max_level]
		upgrade_button.text = "UPGRADE & SPECIALIZE"
		upgrade_button.theme_type_variation = &"PrimaryButton"
	else:
		detail_icon.modulate = Color(0.45, 0.48, 0.55, 0.70)
		detail_level_badge.get_parent().theme_type_variation = &"LockedBadge"
		detail_level_badge.text = "LOCKED"
		upgrade_button.text = "UNLOCK (%d CREDITS)" % tower.unlock_cost
		upgrade_button.theme_type_variation = &"PrimaryButton" if SaveManager.get_credits() >= tower.unlock_cost else &"SecondaryButton"
		
	detail_type_badge.text = ("%s DEFENSE" % stats["damage_type_str"]).to_upper() if tower.collision_layer > 0 else "GROUND TRAP"
	detail_desc.text = tower.description if not tower.description.is_empty() else "Standard defensive installation."
	
	var stat_parts: Array[String] = []
	if stats["has_attack"]:
		stat_parts.append("Damage: %.0f (%s)" % [stats["damage"], stats["damage_type_str"]])
		stat_parts.append("Rate: Every %.2fs" % stats["cooldown"])
		stat_parts.append("DPS: %.1f" % stats["dps"])
	if stats["has_health"]:
		stat_parts.append("Max HP: %.0f" % stats["max_health"])
	if stats["max_targets"] > 1:
		stat_parts.append("Max Targets: %d" % stats["max_targets"])
		
	if stat_parts.is_empty():
		stat_parts.append("Defensive Tactical Installation")
		
	detail_stats.text = " | ".join(stat_parts)

func _on_upgrade_button_pressed() -> void:
	if not _selected_tower:
		return
	if tower_upgrade_popup:
		tower_upgrade_popup.open(_selected_tower)
