class_name CampaignView extends MarginContainer

const STAGE_CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/stage_card.tscn")
const GROUP_CARD_SCENE: PackedScene = preload("res://src/scenes/ui/elements/campaign_group_card.tscn")

@onready var stage_list_container: VBoxContainer = %StageListContainer
@onready var stage_scroll: ScrollContainer = %StageScroll
@onready var select_header: Control = %SelectHeader
@onready var back_button: Button = %GroupBackButton
@onready var header_title: Label = %GroupTitleLabel
@onready var header_series: Label = %GroupSeriesLabel

var _open_group_id: String = ""

func _ready() -> void:
	_open_group_id = GameManager.campaign_group_id
	back_button.pressed.connect(_on_back_pressed)
	SignalBus.stage_unlocked.connect(func(_s): _refresh())
	visibility_changed.connect(func(): if is_visible_in_tree(): _refresh())
	_refresh()

func handle_back() -> bool:
	if _open_group_id.is_empty():
		return false
	_set_open_group("")
	return true

func _refresh() -> void:
	var packs := Registry.get_level_packs()
	if not _open_group_id.is_empty() and not _group_exists(packs, _open_group_id):
		_open_group_id = ""
		GameManager.campaign_group_id = ""
	if _open_group_id.is_empty():
		_show_groups(packs)
	else:
		_show_stages(packs)

func _group_exists(packs: Array[Dictionary], group_id: String) -> bool:
	for pack in packs:
		if str(pack.id) == group_id:
			return true
	return false

func _find_group(packs: Array[Dictionary], group_id: String) -> Dictionary:
	for pack in packs:
		if str(pack.id) == group_id:
			return pack
	return {}

func _show_groups(packs: Array[Dictionary]) -> void:
	select_header.hide()
	_clear_list()
	for pack in packs:
		var card: CampaignGroupCard = GROUP_CARD_SCENE.instantiate() as CampaignGroupCard
		stage_list_container.add_child(card)
		card.setup(pack)
		card.group_selected.connect(_on_group_selected)
	stage_scroll.scroll_vertical = 0

func _show_stages(packs: Array[Dictionary]) -> void:
	var pack := _find_group(packs, _open_group_id)
	if pack.is_empty():
		_show_groups(packs)
		return
	select_header.show()
	header_title.text = str(pack.name)
	header_series.text = str(pack.series).to_upper()
	_clear_list()
	for stage: StageData in pack.stages:
		var card: StageCard = STAGE_CARD_SCENE.instantiate() as StageCard
		stage_list_container.add_child(card)
		card.setup(stage)
		card.stage_selected.connect(_on_stage_selected)
	stage_scroll.scroll_vertical = 0

func _clear_list() -> void:
	for child in stage_list_container.get_children():
		child.queue_free()

func _set_open_group(group_id: String) -> void:
	_open_group_id = group_id
	GameManager.campaign_group_id = group_id
	_refresh()

func _on_group_selected(group_id: String) -> void:
	_set_open_group(group_id)

func _on_back_pressed() -> void:
	_set_open_group("")

func _on_stage_selected(stage: StageData, is_endless: bool = false) -> void:
	if stage:
		var stage_id = Registry.get_stage_id(stage)
		if SaveManager.is_stage_unlocked(stage_id):
			GameManager.is_endless_mode = is_endless
			GameManager.selected_stage = stage
			GameManager.load_view(GameManager.View.LOADOUT)
