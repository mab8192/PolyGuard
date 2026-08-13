class_name InventoryView extends MarginContainer

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for tower in Registry.get_all_towers():
		var card = CARD_SCENE.instantiate() as Card
		card.image = tower.icon
		card.text = tower.display_name
		grid_container.add_child(card)
