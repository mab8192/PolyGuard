class_name CodexView extends MarginContainer

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_reward: Label = %DetailReward
@onready var detail_type_badge: Label = %DetailTypeBadge
@onready var detail_desc: Label = %DetailDesc
@onready var detail_stats_grid: GridContainer = %DetailStatsGrid

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
