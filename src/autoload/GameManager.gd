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
		if stage_root:
			return stage_root.current_stage
		return null

enum View { MAIN_MENU, LOADOUT, GAME }

const MAIN_MENU: PackedScene = preload("res://src/scenes/main_menu.tscn")
#const LOADOUT: PackedScene = preload("res://src/scenes/loadout_selection.tscn")
const GAME: PackedScene = preload("res://src/scenes/game.tscn")

func load_view(view: View) -> void:
	match view:
		View.MAIN_MENU:
			get_tree().change_scene_to_packed(MAIN_MENU)
		View.LOADOUT:
			#get_tree().change_scene_to_packed(LOADOUT)
			print("LOADOUT")
		View.GAME:
			get_tree().change_scene_to_packed(GAME)

func load_stage(stage_data: StageData, loadout: Array[TowerData]) -> void:
	if Engine.is_in_physics_frame():
		call_deferred("_deferred_load_stage", stage_data, loadout)
		return

	_deferred_load_stage(stage_data, loadout)

func _deferred_load_stage(stage_data: StageData, loadout: Array[TowerData]) -> void:
	selected_stage = stage_data
	selected_loadout = loadout
	
	GameManager.load_view(GameManager.View.GAME)

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
