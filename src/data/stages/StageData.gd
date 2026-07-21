class_name StageData extends Resource

# TODO: Implement StageData
# Need to include various info about a stage, e.g. wave data, stage name, allowed towers, etc.

@export var name: String
@export_file("*.json") var wave_file: String


func load() -> void:
	# Load the given wave data file into memory
	pass
