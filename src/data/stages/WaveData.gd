class_name WaveData
extends RefCounted

var wave_number: int = 1
var reward_gold: int = 0
var spawns: Array[SpawnGroup] = []

## Factory method to build a WaveData instance from a JSON dictionary
static func from_dict(dict: Dictionary) -> WaveData:
	var wave := WaveData.new()
	wave.wave_number = dict.get("wave_number", 1)
	wave.reward_gold = dict.get("reward_gold", 0)

	var raw_spawns: Array = dict.get("spawns", [])
	for spawn_dict in raw_spawns:
		if spawn_dict is Dictionary:
			wave.spawns.append(SpawnGroup.from_dict(spawn_dict))

	return wave
