extends Node

# Map of enemy IDs to data-driven EnemyData resources
const ENEMIES: Dictionary[String, EnemyData] = {
	"speeder": preload("res://src/data/enemies/speeder.tres"),
	"tank": preload("res://src/data/enemies/tank.tres"),
	"ghost": preload("res://src/data/enemies/ghost.tres"),
	"sniper": preload("res://src/data/enemies/sniper.tres"),
	"grunt": preload("res://src/data/enemies/grunt.tres")
}

func get_enemy_data(id: String) -> EnemyData:
	return ENEMIES.get(id, null)

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
