extends Node2D

var stage_ids: Array[String] = Registry.STAGES.keys()
@onready var stage_root: StageRoot = $StageRoot
@onready var camera: CameraController = $Camera2D
@onready var hud: HUD = $HUD

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

func handle_back() -> void:
	if hud.victory.visible or hud.defeat.visible:
		return
	var stage := stage_root.current_stage
	if not stage:
		return
	var radial_menu := hud.find_child("RadialMenu", true, false) as RadialMenu
	if radial_menu and radial_menu.is_open():
		radial_menu.close()
	elif stage.is_in_placement_mode():
		stage.exit_placement_mode()
	elif stage.get_selected_tower():
		stage.deselect_tower()
	else:
		hud.open_pause_menu()

func _notification(what: int) -> void:
	var backgrounded := what == NOTIFICATION_APPLICATION_PAUSED or (what == NOTIFICATION_APPLICATION_FOCUS_OUT and OS.has_feature("mobile"))
	if backgrounded and is_node_ready():
		_pause_for_background()

func _pause_for_background() -> void:
	if get_tree().paused or GameManager.get_top_open_popup():
		return
	var stage := stage_root.current_stage
	if stage and stage.wave_is_active:
		hud.open_pause_menu()
