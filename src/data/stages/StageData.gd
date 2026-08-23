@tool
class_name StageData
extends Resource

@export_group("Stage Info")
@export var stage_id: String = "stage_01"
@export var stage_name: String = "Grassland Outpost"
@export var scene: PackedScene ## The scene for this stage
@export var icon: Texture2D = preload("res://vendor/HAMMA.png")

@export_group("Economy & Rules")
@export var starting_energy: int = 600
var starting_gold: int:
	get: return starting_energy
	set(v): starting_energy = v
@export var starting_lives: int = 20
@export var loadout_size: int = 4

@export_group("Wave Configuration")
@export_file("*.json") var wave_data_file: String = ""

# Internal cache of converted WaveData objects and activation mappings
var _waves: Array[WaveData] = []
var _spawner_activation_waves: Dictionary = {} # spawner_id -> wave_index (0-based)
var _exit_activation_waves: Dictionary = {} # exit_id -> wave_index (0-based)

func _load() -> void:
	if wave_data_file.is_empty() or not FileAccess.file_exists(wave_data_file):
		printerr("StageData (%s): Invalid or missing JSON path: %s" % [stage_name, wave_data_file])
		return

	var file := FileAccess.open(wave_data_file, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		printerr("StageData (%s): JSON Parse Error: %s" % [stage_name, json.get_error_message()])
		return
	
	var data = json.data as Array
	if not data:
		printerr("Malformed JSON: ", wave_data_file)
		return

	_waves.clear()
	_spawner_activation_waves.clear()
	_exit_activation_waves.clear()

	# 1. Convert each dictionary to a strongly-typed WaveData object and build activation mappings
	for i in range(data.size()):
		var wave_dict = data[i]
		if wave_dict is Dictionary:
			var wave_obj = WaveData.from_dict(wave_dict)
			_waves.append(wave_obj)

			# Explicit spawner activations declared in wave data
			for s_id in wave_obj.activate_spawners:
				if not _spawner_activation_waves.has(s_id):
					_spawner_activation_waves[s_id] = i

			# Explicit exit activations declared in wave data
			for e_id in wave_obj.activate_exits:
				if not _exit_activation_waves.has(e_id):
					_exit_activation_waves[e_id] = i

			# Implicit activations: first appearance of targeted spawners
			for spawn_group in wave_obj.spawns:
				if not spawn_group.spawner_id.is_empty():
					if not _spawner_activation_waves.has(spawn_group.spawner_id):
						_spawner_activation_waves[spawn_group.spawner_id] = i

## Returns an array of typed WaveData objects parsed from the JSON file.
func get_waves() -> Array[WaveData]:
	if not _waves.is_empty():
		return _waves

	_load()
	return _waves

## Gets a specific WaveData instance by index.
func get_wave(index: int) -> WaveData:
	var waves := get_waves()
	if index >= 0 and index < waves.size():
		return waves[index]
	printerr("StageData (%s): Wave index %d out of bounds." % [stage_name, index])
	return null

## Does this stage have any ghosts?
func has_ghosts() -> bool:
	var waves := get_waves()
	for wave in waves:
		for spawn in wave.spawns:
			if spawn.enemy_type.contains("ghost"): return true
	
	return false

## Returns the 0-based wave index when the spawner activates (0 = Wave 1).
func get_spawner_activation_wave(spawner_id: String) -> int:
	get_waves()
	return _spawner_activation_waves.get(spawner_id, 0)

## Returns the 0-based wave index when the exit activates (0 = Wave 1).
func get_exit_activation_wave(exit_id: String) -> int:
	get_waves()
	return _exit_activation_waves.get(exit_id, 0)

## Returns an array of spawner IDs that first activate on this specific wave index.
func get_activating_spawners_for_wave(wave_index: int) -> Array[String]:
	get_waves()
	var result: Array[String] = []
	for s_id in _spawner_activation_waves:
		if _spawner_activation_waves[s_id] == wave_index:
			result.append(s_id)
	return result

## Returns an array of exit IDs that first activate on this specific wave index.
func get_activating_exits_for_wave(wave_index: int) -> Array[String]:
	get_waves()
	var result: Array[String] = []
	for e_id in _exit_activation_waves:
		if _exit_activation_waves[e_id] == wave_index:
			result.append(e_id)
	return result

func create() -> Stage:
	if not scene:
		push_error("StageData (%s) has no scene assigned!" % resource_path)
		return null

	var stage = scene.instantiate() as Stage
	if not stage:
		push_error("Scene in StageData must inherit from Stage!")
		return null

	stage.data = self
	return stage
