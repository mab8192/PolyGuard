extends Node2D

func _ready() -> void:
	GameManager.camera = $Camera2D
	GameManager.stage_root = $StageRoot

	GameManager.load_stage(Registry.STAGES[1])
