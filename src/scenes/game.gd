extends Node2D

var stage_ids: Array[String] = Registry.STAGES.keys()
var stage_index: int = 0

func start_next_stage() -> void:
	stage_index += 1
	if stage_index < stage_ids.size():
		GameManager.load_stage(Registry.STAGES[stage_ids[stage_index]])

func _ready() -> void:
	SignalBus.stage_completed.connect(_on_stage_complete)
	
	GameManager.camera = $Camera2D
	GameManager.stage_root = $StageRoot
	
	GameManager.load_stage(Registry.STAGES[stage_ids[stage_index]])

func _on_stage_complete() -> void:
	start_next_stage()
