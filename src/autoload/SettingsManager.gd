extends Node

const SAVE_PATH = "user://settings.cfg"

var _config := ConfigFile.new()

func _ready() -> void:
	load_settings()

func set_bus_volume(bus_name: String, linear_val: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))
		_config.set_value("audio", bus_name, linear_val)
		_config.save(SAVE_PATH)

func get_bus_volume(bus_name: String, default_val: float = 1.0) -> float:
	return _config.get_value("audio", bus_name, default_val)

func load_settings() -> void:
	var err = _config.load(SAVE_PATH)
	if err == OK:
		for bus_name in ["Music", "SFX", "Master"]:
			if _config.has_section_key("audio", bus_name):
				var linear_val = _config.get_value("audio", bus_name, 1.0)
				var bus_idx = AudioServer.get_bus_index(bus_name)
				if bus_idx != -1:
					AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))
