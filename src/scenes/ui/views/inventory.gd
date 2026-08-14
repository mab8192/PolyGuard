class_name InventoryView extends MarginContainer

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_cost: Label = %DetailCost
@onready var detail_type_badge: Label = %DetailTypeBadge
@onready var detail_desc: Label = %DetailDesc
@onready var detail_stats: Label = %DetailStats

var _cards: Array[Card] = []
var _selected_tower: TowerData = null

func _ready() -> void:
	_populate_towers()

func _populate_towers() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_cards.clear()

	var all_towers = Registry.get_all_towers()
	for tower in all_towers:
		var card = CARD_SCENE.instantiate() as Card
		grid_container.add_child(card)
		card.setup(tower.icon, tower.display_name, "%dg" % tower.cost, tower)
		card.card_clicked.connect(_on_card_clicked)
		_cards.append(card)
		
	if all_towers.size() > 0:
		_select_tower(all_towers[0])

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
		
	detail_icon.texture = tower.icon
	detail_title.text = tower.display_name
	detail_cost.text = "%dg" % tower.cost
	detail_type_badge.text = "BLOCKS ENEMIES" if tower.is_solid else "GROUND TRAP"
	detail_desc.text = tower.description if not tower.description.is_empty() else "Standard defensive installation."
	
	var stat_parts: Array[String] = []
	if tower.attack:
		stat_parts.append("Attack Damage: %d" % tower.attack.damage)
		stat_parts.append("Attack Cooldown: Every %.1fs" % tower.attack.cooldown)
	if tower.targeting:
		stat_parts.append("Target: %s" % _get_strategy_name(tower.targeting.strategy))
	if tower.health:
		stat_parts.append("Max HP: %d" % tower.health.max_health)
	#if tower.effect_applier and tower.effect_applier.effect:
		#stat_parts.append("✨ Effect: %s" % tower.effect_applier.effect.name)
		
	detail_stats.text = " | ".join(stat_parts)

func _get_strategy_name(strategy: int) -> String:
	match strategy:
		TargetingComponent.Strategy.FIRST:
			return "First"
		TargetingComponent.Strategy.LAST:
			return "Last"
		TargetingComponent.Strategy.STRONGEST:
			return "Strongest"
		TargetingComponent.Strategy.CLOSEST:
			return "Closest"
		_:
			return "Default"
