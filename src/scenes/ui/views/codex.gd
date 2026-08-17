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
		
	var stats = enemy.get_stats()
	detail_icon.texture = enemy.icon
	detail_title.text = enemy.display_name
	detail_reward.text = "+%d Energy" % enemy.energy_reward
	detail_type_badge.text = stats.get("type", "HOSTILE UNIT")
	detail_desc.text = enemy.description if not enemy.description.is_empty() else "Identified hostile geometric combat unit."
	
	var lines: Array[String] = stats.get("stat_lines", [])
	detail_stats.text = "   •   ".join(lines)
