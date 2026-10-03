class_name CampaignGroupCard extends PanelContainer

signal group_selected(group_id: String)

var group: Dictionary = {}

@onready var series_label: Label = %SeriesLabel
@onready var title_label: Label = %TitleLabel
@onready var progress_label: Label = %ProgressLabel
@onready var action_label: Label = %ActionLabel

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	if not group.is_empty():
		_render()

func setup(p_group: Dictionary) -> void:
	group = p_group
	if is_inside_tree():
		_render()

func _render() -> void:
	if group.is_empty():
		return
	var stages: Array = group.stages
	var cleared := 0
	var unlocked := 0
	var stars := 0
	for stage: StageData in stages:
		if SaveManager.is_stage_unlocked(stage.stage_id):
			unlocked += 1
		if SaveManager.is_stage_completed(stage.stage_id):
			cleared += 1
			stars += int(SaveManager.get_stage_record(stage.stage_id).get("stars", 0))
	series_label.text = str(group.series).to_upper()
	title_label.text = str(group.name)
	var total := stages.size()
	if unlocked == 0:
		progress_label.text = "Clear the previous set to unlock"
		action_label.text = "LOCKED"
		self_modulate = Color(0.72, 0.74, 0.8, 1.0)
	elif cleared >= total:
		progress_label.text = "Complete  ·  %d / %d stars" % [stars, total * 3]
		action_label.text = "OPEN  >"
		self_modulate = Color.WHITE
	else:
		progress_label.text = "%d / %d cleared  ·  %d / %d stars" % [cleared, total, stars, total * 3]
		action_label.text = "OPEN  >"
		self_modulate = Color.WHITE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if DragScrollContainer.is_globally_dragging:
				return
			group_selected.emit(str(group.id))
