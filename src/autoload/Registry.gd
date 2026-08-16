extends Node

# Map of enemy IDs to data-driven EnemyData resources
var ENEMIES: Dictionary[String, EnemyData] = {}

func get_enemy_data(id: String) -> EnemyData:
	return ENEMIES.get(id, null)
	
func get_all_enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	for key in ENEMIES:
		result.append(ENEMIES[key])
	return result

# Map of stage IDs to data-driven StageData resources
var STAGES: Dictionary[String, StageData] = {}

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
var TOWERS: Dictionary[String, TowerData] = {}

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

func _init() -> void:
	_load_registry()

func _load_registry() -> void:
	ENEMIES = {
		"speeder": load("res://src/data/enemies/speeder.tres"),
		"tank": load("res://src/data/enemies/tank.tres"),
		"ghost": load("res://src/data/enemies/ghost.tres"),
		"sniper": load("res://src/data/enemies/sniper.tres"),
		"light": load("res://src/data/enemies/light.tres"),
		"grunt": load("res://src/data/enemies/grunt.tres"),
		"heavy": load("res://src/data/enemies/heavy.tres"),
		"citadel": load("res://src/data/enemies/citadel.tres"),
		"splitter": load("res://src/data/enemies/splitter.tres")
	}
	
	STAGES = {
		"stage_01": load("res://src/data/stages/stage_01.tres"),
		"stage_02": load("res://src/data/stages/stage_02.tres"),
		"stage_03": load("res://src/data/stages/stage_03.tres"),
		"stage_04": load("res://src/data/stages/stage_04.tres"),
		"stage_05": load("res://src/data/stages/stage_05.tres"),
		"stage_06": load("res://src/data/stages/stage_06.tres"),
		"stage_07": load("res://src/data/stages/stage_07.tres"),
		"stage_08": load("res://src/data/stages/stage_08.tres"),
		"stage_09": load("res://src/data/stages/stage_09.tres"),
		"stage_10": load("res://src/data/stages/stage_10.tres"),
		"stage_11": load("res://src/data/stages/stage_11.tres"),
		"stage_12": load("res://src/data/stages/stage_12.tres"),
		"stage_13": load("res://src/data/stages/stage_13.tres"),
		"stage_14": load("res://src/data/stages/stage_14.tres"),
		"stage_15": load("res://src/data/stages/stage_15.tres"),
		"stage_16": load("res://src/data/stages/stage_16.tres"),
		"stage_17": load("res://src/data/stages/stage_17.tres"),
		"stage_18": load("res://src/data/stages/stage_18.tres"),
		"stage_19": load("res://src/data/stages/stage_19.tres"),
		"stage_20": load("res://src/data/stages/stage_20.tres"),
		"test_stage": load("res://src/data/stages/TestStage.tres"),
	}
	
	TOWERS = {
		"archer_tower": load("res://src/data/towers/archer_tower.tres"),
		"arrow_wall": load("res://src/data/towers/arrow_wall.tres"),
		"crossbow": load("res://src/data/towers/crossbow.tres"),
		"flamethrower": load("res://src/data/towers/flamethrower.tres"),
		"barricade": load("res://src/data/towers/barricade.tres"),
		"poison_trap": load("res://src/data/towers/poison_trap.tres"),
		"tesla_tower": load("res://src/data/towers/tesla_tower.tres"),
		"bomb_tower": load("res://src/data/towers/bomb_tower.tres"),
		"brimstone": load("res://src/data/towers/brimstone.tres"),
		"tar_trap": load("res://src/data/towers/tar_trap.tres"),
		"displacer": load("res://src/data/towers/displacer.tres"),
		"ice_trap": load("res://src/data/towers/ice_trap.tres"),
		"corrosive_vapor": load("res://src/data/towers/corrosive_vapor.tres"),
		"artillery": load("res://src/data/towers/artillery.tres"),
		"carpet_bomb_artillery": load("res://src/data/towers/artillery.tres"),
	}
