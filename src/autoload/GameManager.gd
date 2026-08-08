extends Node

var camera: Camera2D
var stage_root: StageRoot

var current_stage: Stage:
	get:
		return stage_root.current_stage

func _ready() -> void:
	get_viewport().size_changed.connect(_update_camera)
	
func load_stage(stage_data: StageData) -> void:
	stage_root.load_stage(stage_data)
	_update_camera()

func _update_camera() -> void:
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
	camera.global_position = bounds.get_center()
	camera.zoom = Vector2(target_zoom, target_zoom)
