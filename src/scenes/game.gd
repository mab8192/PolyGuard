extends Node2D

var stage_ids: Array[String] = Registry.STAGES.keys()
@onready var stage_root: StageRoot = $StageRoot
@onready var camera: CameraController = $Camera2D

func _ready() -> void:
	GameManager.camera = $Camera2D
	GameManager.stage_root = $StageRoot
		
	var stage_to_load = GameManager.selected_stage
	if not stage_to_load:
		if not stage_ids.is_empty():
			stage_to_load = Registry.STAGES[stage_ids[0]]
			GameManager.selected_stage = stage_to_load
	
	if GameManager.selected_loadout.is_empty():
		var saved_ids = SaveManager.get_selected_loadout()
		for t_id in saved_ids:
			if SaveManager.is_tower_unlocked(t_id):
				var t = Registry.get_tower_data(t_id)
				if t:
					var lvl = SaveManager.get_tower_level(t_id)
					var choice = SaveManager.get_tower_choice(t_id)
					GameManager.selected_loadout.append(t.get_scaled_copy(lvl, choice))
					if GameManager.selected_loadout.size() >= 4:
						break
		
		if GameManager.selected_loadout.is_empty():
			var all_towers = Registry.get_all_towers()
			for t in all_towers:
				var t_id = Registry.get_tower_id(t)
				if SaveManager.is_tower_unlocked(t_id):
					var lvl = SaveManager.get_tower_level(t_id)
					var choice = SaveManager.get_tower_choice(t_id)
					GameManager.selected_loadout.append(t.get_scaled_copy(lvl, choice))
					if GameManager.selected_loadout.size() >= 4:
						break
 
	if stage_to_load:
		stage_root.load_stage(stage_to_load)
		_update_camera()
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _update_camera() -> void:
	if not stage_root.current_stage or not camera:
		return
	camera.setup_for_stage(stage_root.current_stage)

func _on_viewport_size_changed() -> void:
	if camera:
		camera.on_viewport_size_changed()
