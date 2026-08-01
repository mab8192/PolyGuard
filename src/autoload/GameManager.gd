extends Node

var current_stage: Stage = null
var camera: Camera2D
var stage_root: Node2D

func _ready() -> void:
	get_viewport().size_changed.connect(update_camera)

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
	update_camera()

func update_camera() -> void:
	if not current_stage or not camera:
		return
		
	var bounds: Rect2 = current_stage.get_map_pixel_rect()
	var viewport_size = camera.get_viewport_rect().size
	
	# Determine the best zoom to fit the stage bounds in the current viewport
	var padding = 0.95
	var zoom_x = (viewport_size.x * padding) / bounds.size.x
	var zoom_y = (viewport_size.y * padding) / bounds.size.y
	var target_zoom = min(zoom_x, zoom_y)
	
	# Apply zoom
	camera.zoom = Vector2(target_zoom, target_zoom)
