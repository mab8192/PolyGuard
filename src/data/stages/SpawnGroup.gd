class_name SpawnGroup
extends RefCounted

var enemy_type: String = ""
var count: int = 1
var interval: float = 1.0
var delay: float = 0.0

## Factory method to build a SpawnGroup instance from a JSON dictionary
static func from_dict(dict: Dictionary) -> SpawnGroup:
	var group := SpawnGroup.new()
	group.enemy_type = dict.get("enemy_type", "")
	group.count = dict.get("count", 1)
	group.interval = dict.get("interval", 1.0)
	group.delay = dict.get("delay", 0.0)
	return group
