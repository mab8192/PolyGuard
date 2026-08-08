class_name StageRoot extends Node2D

## Reference to the currently loaded stage
var current_stage: Stage

@onready var enemies: Node2D = $Enemies
@onready var effects: Node2D = $Effects

func load_stage(stage_data: StageData) -> Stage:
	clear()

	current_stage = stage_data.create()
	if not current_stage:
		push_error("Failed to create stage from StageData!")
		return
		
	add_child(current_stage)
	
	return current_stage

func clear() -> void:
	if current_stage:
		current_stage.queue_free()

	for c in enemies.get_children():
		c.queue_free()
	for c in effects.get_children():
		c.queue_free()

	current_stage = null
