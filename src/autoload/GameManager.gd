extends Node

var camera: Camera2D
var stage_root: StageRoot

# Transition states
var selected_stage: StageData
var selected_loadout: Array[TowerData] = []
var loadout_presets: Dictionary = {} # int -> Array[TowerData]
var active_preset_index: int = 1

var current_stage: Stage:
	get:
		return stage_root.current_stage

func _ready() -> void:
	get_viewport().size_changed.connect(_update_camera)
	
func load_stage(stage_data: StageData) -> void:
	if Engine.is_in_physics_frame():
		call_deferred("_deferred_load_stage", stage_data)
		return

	_deferred_load_stage(stage_data)

func _deferred_load_stage(stage_data: StageData) -> void:
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

func start_game(stage_data: StageData = null, loadout: Array[TowerData] = []) -> void:
	if stage_data:
		selected_stage = stage_data
	if not loadout.is_empty():
		selected_loadout = loadout
	get_tree().change_scene_to_file("res://src/scenes/game.tscn")

func get_next_stage() -> StageData:
	var stages = Registry.get_all_stages()
	if stages.is_empty():
		return null
	if not selected_stage:
		return stages[0]
	var idx = stages.find(selected_stage)
	if idx != -1 and idx + 1 < stages.size():
		return stages[idx + 1]
	return null
