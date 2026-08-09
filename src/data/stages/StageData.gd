class_name StageData
extends Resource

@export_group("Stage Info")
@export var stage_id: String = "stage_01"
@export var stage_name: String = "Grassland Outpost"
@export var scene: PackedScene ## The scene for this stage
@export var icon: Texture2D = preload("res://vendor/HAMMA.png")

@export_group("Economy & Rules")
@export var starting_gold: int = 600
@export var starting_lives: int = 20

@export_group("Wave Configuration")
@export_file("*.json") var wave_data_file: String = ""

# Internal cache of converted WaveData objects
var _waves: Array[WaveData] = []

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

	# Convert each dictionary to a strongly-typed WaveData object
	for wave_dict in data:
		if wave_dict is Dictionary:
			_waves.append(WaveData.from_dict(wave_dict))

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
