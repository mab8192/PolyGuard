class_name CodexView extends Control

const CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/card.tscn")

@onready var grid_container: GridContainer = %GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for enemy in Registry.get_all_enemies():
		var card = CARD_SCENE.instantiate() as Card
		card.image = enemy.icon
		card.text = enemy.display_name
		grid_container.add_child(card)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
