class_name CampaignView extends MarginContainer

@onready var carousel: Carousel = %Carousel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var items: Array[Dictionary] = []
	for stage in Registry.get_all_stages():
		items.append({
			"text": stage.stage_name,
			"image": stage.icon,
			"payload": stage
		})
	
	carousel.set_items(items)
	carousel.item_selected.connect(_on_carousel_select)

func _on_carousel_select(payload: Variant) -> void:
	if payload is StageData:
		GameManager.selected_stage = payload
		GameManager.selected_loadout = Registry.get_all_towers()
		GameManager.load_view(GameManager.View.GAME)
