class_name CampaignView extends MarginContainer

const STAGE_CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/stage_card.tscn")

@onready var stage_list_container: VBoxContainer = %StageListContainer

func _ready() -> void:
	_populate_stages()

func _populate_stages() -> void:
	for child in stage_list_container.get_children():
		child.queue_free()
	
	var stages = Registry.get_all_stages()
	for stage in stages:
		var card: StageCard = STAGE_CARD_SCENE.instantiate() as StageCard
		stage_list_container.add_child(card)
		card.setup(stage)
		card.stage_selected.connect(_on_stage_selected)

func _on_stage_selected(stage: StageData) -> void:
	if stage:
		GameManager.selected_stage = stage
		GameManager.load_view(GameManager.View.LOADOUT)
