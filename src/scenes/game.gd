extends Node2D

var stage_ids: Array[String] = Registry.STAGES.keys()
var stage_index: int = 0

func start_next_stage() -> void:
	stage_index += 1
	if stage_index < stage_ids.size():
		GameManager.load_stage(Registry.STAGES[stage_ids[stage_index]])

func _ready() -> void:
	GameManager.camera = $Camera2D
	GameManager.stage_root = $StageRoot
	
	var stage_to_load = GameManager.selected_stage
	if not stage_to_load:
		if not stage_ids.is_empty():
			stage_to_load = Registry.STAGES[stage_ids[0]]
			GameManager.selected_stage = stage_to_load
	
	if stage_to_load:
		GameManager.load_stage(stage_to_load)
