class_name SpawnGroup
extends RefCounted

var enemy_type: String = ""
var count: int = 1
var interval: float = 1.0
var delay: float = 0.0
var spawner_id: String = ""

## Factory method to build a SpawnGroup instance from a JSON dictionary
static func from_dict(dict: Dictionary) -> SpawnGroup:
	var group := SpawnGroup.new()
	group.enemy_type = dict.get("enemy_type", "")
	group.count = int(dict.get("count", 1))
	group.interval = float(dict.get("interval", 1.0))
	group.delay = float(dict.get("delay", 0.0))
	group.spawner_id = dict.get("spawner_id", dict.get("spawner", ""))
	return group
