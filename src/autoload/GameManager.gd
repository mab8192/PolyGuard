extends Node

var current_stage: Stage = null
var camera: Camera2D
var stage_root: Node2D

func load_stage(path: String) -> void:
	# 1. Clean up old stage
	if current_stage:
		current_stage.queue_free()
		current_stage = null
	
	# 2. Instantiate new stage
	var stage_packed: PackedScene = load(path)
	current_stage = stage_packed.instantiate() as Stage
	stage_root.add_child(current_stage)
	
	# 3. Configure camera for the newly loaded stage
	_setup_stage(current_stage)

## Setup the given stage. Update the camera, set economy, etc.
func _setup_stage(stage: Stage) -> void:
	var bounds: Rect2 = stage.get_map_pixel_rect()
	
	# Lock the Camera2D scroll limits to the map edges
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	
	# Center the camera on the middle of the stage
	camera.global_position = bounds.get_center()
