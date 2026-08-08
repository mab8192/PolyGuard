extends Node2D

var stage_num: int = 0

func start_next_stage() -> void:
	stage_num += 1
	GameManager.load_stage(Registry.STAGES[stage_num])

func _ready() -> void:
	SignalBus.stage_completed.connect(_on_stage_complete)
	
	GameManager.camera = $Camera2D
	GameManager.stage_root = $StageRoot
	
	GameManager.load_stage(Registry.STAGES[stage_num])

func _on_stage_complete() -> void:
	start_next_stage()
