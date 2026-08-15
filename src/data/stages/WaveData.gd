class_name WaveData
extends RefCounted

var wave_number: int = 1
var reward_energy: int = 0
var reward_gold: int:
	get: return reward_energy
	set(v): reward_energy = v
var spawns: Array[SpawnGroup] = []

## Dynamic stage activations on wave start
var activate_spawners: Array[String] = []
var activate_exits: Array[String] = []

## Factory method to build a WaveData instance from a JSON dictionary
static func from_dict(dict: Dictionary) -> WaveData:
	var wave := WaveData.new()
	wave.wave_number = int(dict.get("wave_number", 1))
	wave.reward_energy = int(dict.get("reward_energy", dict.get("reward_gold", 0)))

	var raw_spawns: Array = dict.get("spawns", [])
	for spawn_dict in raw_spawns:
		if spawn_dict is Dictionary:
			wave.spawns.append(SpawnGroup.from_dict(spawn_dict))

	for id in dict.get("activate_spawners", []):
		wave.activate_spawners.append(str(id))
	for id in dict.get("activate_exits", []):
		wave.activate_exits.append(str(id))

	return wave
