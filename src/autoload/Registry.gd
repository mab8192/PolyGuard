extends Node

# Map of enemy IDs to data-driven EnemyData resources
const ENEMIES: Dictionary[String, EnemyData] = {
	"speeder": preload("res://src/data/enemies/speeder.tres"),
	"tank": preload("res://src/data/enemies/tank.tres"),
	"ghost": preload("res://src/data/enemies/ghost.tres"),
	"sniper": preload("res://src/data/enemies/sniper.tres"),
	"light": preload("res://src/data/enemies/light.tres"),
	"grunt": preload("res://src/data/enemies/grunt.tres"),
	"heavy": preload("res://src/data/enemies/heavy.tres"),
	"citadel": preload("res://src/data/enemies/citadel.tres"),
	"splitter": preload("res://src/data/enemies/splitter.tres")
}

func get_enemy_data(id: String) -> EnemyData:
	return ENEMIES.get(id, null)
	
func get_all_enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	for key in ENEMIES:
		result.append(ENEMIES[key])
	return result

# Map of stage IDs to data-driven StageData resources
const STAGES: Dictionary[String, StageData] = {
	"stage_01": preload("res://src/data/stages/stage_01.tres"),
	"stage_02": preload("res://src/data/stages/stage_02.tres"),
	"stage_03": preload("res://src/data/stages/stage_03.tres"),
	"stage_04": preload("res://src/data/stages/stage_04.tres"),
	"stage_05": preload("res://src/data/stages/stage_05.tres"),
	"stage_06": preload("res://src/data/stages/stage_06.tres"),
	"stage_07": preload("res://src/data/stages/stage_07.tres"),
	"stage_08": preload("res://src/data/stages/stage_08.tres"),
	"test_stage": preload("res://src/data/stages/TestStage.tres"),
}

func get_stage_data(id: String) -> StageData:
	return STAGES.get(id, null)

func get_all_stages() -> Array[StageData]:
	var result: Array[StageData] = []
	for key in STAGES:
		result.append(STAGES[key])
	return result

func get_stage_id(stage: StageData) -> String:
	if not stage:
		return ""
	if not stage.stage_id.is_empty():
		return stage.stage_id
	for key in STAGES:
		if STAGES[key] == stage:
			return key
	return ""

# Map of tower IDs to data-driven TowerData resources
const TOWERS: Dictionary[String, TowerData] = {
	"archer_tower": preload("res://src/data/towers/archer_tower.tres"),
	"arrow_wall": preload("res://src/data/towers/arrow_wall.tres"),
	"barricade": preload("res://src/data/towers/barricade.tres"),
	"poison_trap": preload("res://src/data/towers/poison_trap.tres"),
	"tesla_tower": preload("res://src/data/towers/tesla_tower.tres"),
	"bomb_tower": preload("res://src/data/towers/bomb_tower.tres"),
	"brimstone": preload("res://src/data/towers/brimstone.tres"),
	"tar_trap": preload("res://src/data/towers/tar_trap.tres"),
}

func get_tower_data(id: String) -> TowerData:
	return TOWERS.get(id, null)

func get_all_towers() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for key in TOWERS:
		result.append(TOWERS[key])
	return result

func get_tower_id(tower: TowerData) -> String:
	if not tower:
		return ""
	if not tower.tower_id.is_empty():
		return tower.tower_id
	for key in TOWERS:
		if TOWERS[key] == tower:
			return key
	return ""
