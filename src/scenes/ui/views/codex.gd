class_name CodexView extends MarginContainer

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_reward: Label = %DetailReward
@onready var detail_type_badge: Label = %DetailTypeBadge
@onready var detail_desc: Label = %DetailDesc
@onready var detail_stats: Label = %DetailStats

var _cards: Array[Card] = []
var _selected_enemy: EnemyData = null

func _ready() -> void:
	_populate_enemies()

func _populate_enemies() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_cards.clear()

	var all_enemies = Registry.get_all_enemies()
	for enemy in all_enemies:
		var card = CARD_SCENE.instantiate() as Card
		grid_container.add_child(card)
		card.setup(enemy.icon, enemy.display_name, "", enemy)
		card.card_clicked.connect(_on_card_clicked)
		_cards.append(card)
		
	if all_enemies.size() > 0:
		_select_enemy(all_enemies[0])

func _on_card_clicked(card: Card) -> void:
	if card.data is EnemyData:
		_select_enemy(card.data)

func _select_enemy(enemy: EnemyData) -> void:
	_selected_enemy = enemy
	
	for card in _cards:
		card.set_card_selected(card.data == enemy)
		
	_update_details(enemy)

func _update_details(enemy: EnemyData) -> void:
	if not enemy:
		return
		
	detail_icon.texture = enemy.icon
	detail_title.text = enemy.display_name
	detail_reward.text = "+%d Energy" % enemy.energy_reward
	detail_type_badge.text = "GHOST UNIT" if enemy.type == Enemy.EnemyType.GHOST else "PHYSICAL UNIT"
	detail_desc.text = "Identified hostile geometric combat unit."
	
	var stat_parts: Array[String] = []
	if enemy.health:
		stat_parts.append("HP: %d" % enemy.health.max_health)
		stat_parts.append("Armor: %d" % enemy.health.armor)
		stat_parts.append("Magic Resistance: %d" % enemy.health.magic_resistance)
	if enemy.movement:
		stat_parts.append("Speed: %d" % int(enemy.movement.max_speed))
	stat_parts.append("Penalty: %d Lives" % enemy.lives_penalty)
	stat_parts.append("Nav Strategy: %s" % _get_nav_name(enemy.nav_strategy))
	
	if enemy.attack:
		stat_parts.append("Attack Damage: %d" % enemy.attack.damage)
		stat_parts.append("Attack Cooldown: %.1f s" % enemy.attack.cooldown)
	if enemy.splitter:
		stat_parts.append("Splits on Death: %d" % enemy.splitter.number_of_copies)
		stat_parts.append("Maximum Splits: %d" % enemy.splitter.max_splits)
		
	detail_stats.text = " | ".join(stat_parts)

func _get_nav_name(strategy: int) -> String:
	match strategy:
		NavigationComponent.NavStrategy.CLOSEST:
			return "Closest"
		NavigationComponent.NavStrategy.FARTHEST:
			return "Farthest"
		NavigationComponent.NavStrategy.FIRST:
			return "First"
		_:
			return "Error"
