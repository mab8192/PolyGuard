class_name CampaignView extends MarginContainer

const STAGE_CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/stage_card.tscn")

@onready var stage_list_container: VBoxContainer = %StageListContainer

func _ready() -> void:
	SignalBus.stage_unlocked.connect(func(_s): _populate_stages())
	visibility_changed.connect(func(): if is_visible_in_tree(): _populate_stages())
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

func _on_stage_selected(stage: StageData, is_endless: bool = false) -> void:
	if stage:
		var stage_id = Registry.get_stage_id(stage)
		if SaveManager.is_stage_unlocked(stage_id):
			GameManager.is_endless_mode = is_endless
			GameManager.selected_stage = stage
			GameManager.load_view(GameManager.View.LOADOUT)
