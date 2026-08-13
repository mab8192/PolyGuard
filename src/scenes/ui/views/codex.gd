class_name CodexView extends MarginContainer

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer

func _ready() -> void:
	for enemy in Registry.get_all_enemies():
		var card = CARD_SCENE.instantiate() as Card
		card.image = enemy.icon
		card.text = enemy.display_name
		grid_container.add_child(card)
