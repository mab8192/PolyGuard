extends Node

var camera: Camera2D
var stage_root: StageRoot

enum GameMode { CAMPAIGN, ENDLESS }

# Transition states
var selected_stage: StageData
var selected_loadout: Array[TowerData] = []
var loadout_presets: Dictionary = {} # int -> Array[TowerData]
var active_preset_index: int = 1
var target_main_menu_tab: int = -1
var current_game_mode: GameMode = GameMode.CAMPAIGN

var is_endless_mode: bool:
	get: return current_game_mode == GameMode.ENDLESS
	set(v): current_game_mode = GameMode.ENDLESS if v else GameMode.CAMPAIGN

var current_stage: Stage:
	get:
		if stage_root:
			return stage_root.current_stage
		return null

enum View { MAIN_MENU, LOADOUT, GAME }

const MAIN_MENU: PackedScene = preload("res://src/scenes/main_menu.tscn")
const LOADOUT: PackedScene = preload("res://src/scenes/loadout_selection.tscn")
const GAME: PackedScene = preload("res://src/scenes/game.tscn")
const DEV_CHEAT_MENU_SCENE: PackedScene = preload("res://src/scenes/ui/popups/dev_cheat_menu.tscn")

var dev_cheat_menu: DevCheatMenu = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dev_cheat_menu = DEV_CHEAT_MENU_SCENE.instantiate() as DevCheatMenu
	add_child(dev_cheat_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F1 or event.keycode == KEY_QUOTELEFT:
			if dev_cheat_menu:
				dev_cheat_menu.toggle()
				get_viewport().set_input_as_handled()

func load_view(view: View) -> void:
	Engine.time_scale = 1.0
	match view:
		View.MAIN_MENU:
			get_tree().change_scene_to_packed(MAIN_MENU)
		View.LOADOUT:
			get_tree().change_scene_to_packed(LOADOUT)
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
