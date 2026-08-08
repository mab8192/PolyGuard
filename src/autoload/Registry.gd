extends Node

# Map of enemy types to scenes
const ENEMY_MAP: Dictionary = {
	"speeder": "res://src/scenes/enemies/speeder.tscn",
	"tank": "res://src/scenes/enemies/tank.tscn",
	"ghost": "res://src/scenes/enemies/ghost.tscn",
}

# Array of paths to stage scenes
const STAGES: Array[String] = [
	"res://src/scenes/stages/Stage1.tscn",
	"res://src/scenes/stages/Stage2.tscn",
	"res://src/scenes/stages/Stage3.tscn"
]

# Map of tower IDs to data-driven TowerData resources
const TOWERS: Dictionary[String, TowerData] = {
	"archer_tower": preload("res://src/data/towers/archer_tower.tres"),
	"barricade": preload("res://src/data/towers/barricade.tres"),
	"tar_trap": preload("res://src/data/towers/tar_trap.tres")
}

func get_tower_data(id: String) -> TowerData:
	return TOWERS.get(id, null)

func get_all_towers() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for key in TOWERS:
		result.append(TOWERS[key])
	return result
