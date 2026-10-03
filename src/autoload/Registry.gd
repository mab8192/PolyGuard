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
	result.sort_custom(func(a: StageData, b: StageData) -> bool:
		if a.pack_order != b.pack_order:
			return a.pack_order < b.pack_order
		return a.stage_id < b.stage_id
	)
	return result

## Inclusive stage-number ranges. Stage 0, the tutorial, stays with the first ten.
const CAMPAIGN_GROUP_RANGES: Array[Vector2i] = [
	Vector2i(0, 10),
	Vector2i(11, 20),
	Vector2i(21, 30),
	Vector2i(31, 40),
]

func get_level_packs() -> Array[Dictionary]:
	var by_number: Dictionary = {}
	var extras: Array[StageData] = []
	for stage in get_all_stages():
		var number := _campaign_stage_number(stage)
		if stage.stage_id.begins_with("stage_"):
			by_number[number] = stage
		else:
			extras.append(stage)
	var packs: Array[Dictionary] = []
	for order in CAMPAIGN_GROUP_RANGES.size():
		var range: Vector2i = CAMPAIGN_GROUP_RANGES[order]
		var chunk: Array[StageData] = []
		for number in range(range.x, range.y + 1):
			if by_number.has(number):
				chunk.append(by_number[number])
				by_number.erase(number)
		if chunk.is_empty():
			continue
		var series := chunk[0].pack_name if not chunk[0].pack_name.is_empty() else "Frontier"
		packs.append({
			"id": "stages_%d_%d" % [range.x, range.y],
			"name": "Stages %d–%d" % [range.x, range.y],
			"series": series,
			"order": order,
			"stages": chunk,
		})
	if not by_number.is_empty() or not extras.is_empty():
		var chunk: Array[StageData] = extras.duplicate()
		var leftover_numbers: Array = by_number.keys()
		leftover_numbers.sort()
		for number in leftover_numbers:
			chunk.append(by_number[number])
		if not chunk.is_empty():
			packs.append({
				"id": "stages_extra",
				"name": "More Stages",
				"series": "Campaign",
				"order": packs.size(),
				"stages": chunk,
			})
	return packs

func _campaign_stage_number(stage: StageData) -> int:
	if stage.stage_id.begins_with("stage_"):
		return stage.stage_id.trim_prefix("stage_").to_int()
	return 0

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

func get_all_towers_sorted() -> Array[TowerData]:
	var result: Array[TowerData] = get_all_towers()
	result.sort_custom(func(a: TowerData, b: TowerData) -> bool:
		var a_id = get_tower_id(a)
		var b_id = get_tower_id(b)
		var a_unlocked = SaveManager.is_tower_unlocked(a_id)
		var b_unlocked = SaveManager.is_tower_unlocked(b_id)
		if a_unlocked != b_unlocked:
			return a_unlocked
		var a_avail = a.is_available()
		var b_avail = b.is_available()
		if a_avail != b_avail:
			return a_avail
		if a.cost != b.cost:
			return a.cost < b.cost
		return a.display_name < b.display_name
	)
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
		"splitter": load("res://src/data/enemies/splitter.tres"),
		"bomber": load("res://src/data/enemies/bomber.tres"),
		"light_ghost": load("res://src/data/enemies/light_ghost.tres"),
		"heavy_ghost": load("res://src/data/enemies/heavy_ghost.tres"),
		"healer": load("res://src/data/enemies/healer.tres"),
		"booster": load("res://src/data/enemies/booster.tres"),
	}
	
	STAGES = {
		"stage_00": load("res://src/data/stages/stage_00.tres"),
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
		"stage_21": load("res://src/data/stages/stage_21.tres"),
		"stage_22": load("res://src/data/stages/stage_22.tres"),
		"stage_23": load("res://src/data/stages/stage_23.tres"),
		"stage_24": load("res://src/data/stages/stage_24.tres"),
		"stage_25": load("res://src/data/stages/stage_25.tres"),
		"stage_26": load("res://src/data/stages/stage_26.tres"),
		"stage_27": load("res://src/data/stages/stage_27.tres"),
		"stage_28": load("res://src/data/stages/stage_28.tres"),
		"stage_29": load("res://src/data/stages/stage_29.tres"),
		"stage_30": load("res://src/data/stages/stage_30.tres"),
		"stage_31": load("res://src/data/stages/stage_31.tres"),
		"stage_32": load("res://src/data/stages/stage_32.tres"),
		"stage_33": load("res://src/data/stages/stage_33.tres"),
		"stage_34": load("res://src/data/stages/stage_34.tres"),
		"stage_35": load("res://src/data/stages/stage_35.tres"),
		"stage_36": load("res://src/data/stages/stage_36.tres"),
		"stage_37": load("res://src/data/stages/stage_37.tres"),
		"stage_38": load("res://src/data/stages/stage_38.tres"),
		"stage_39": load("res://src/data/stages/stage_39.tres"),
		"stage_40": load("res://src/data/stages/stage_40.tres"),
		#"test_stage": load("res://src/data/stages/TestStage.tres"),
	}
	
	TOWERS = {
		"archer_tower": load("res://src/data/towers/archer_tower.tres"),
		"arrow_wall": load("res://src/data/towers/arrow_wall.tres"),
		"wind_wall": load("res://src/data/towers/wind_wall.tres"),
		"acid_wall": load("res://src/data/towers/acid_wall.tres"),
		"crossbow": load("res://src/data/towers/crossbow.tres"),
		"flamethrower": load("res://src/data/towers/flamethrower.tres"),
		"barricade": load("res://src/data/towers/barricade.tres"),
		"poison_trap": load("res://src/data/towers/poison_trap.tres"),
		"tesla_tower": load("res://src/data/towers/tesla_tower.tres"),
		"bomb_tower": load("res://src/data/towers/bomb_tower.tres"),
		"brimstone": load("res://src/data/towers/brimstone.tres"),
		"tar_trap": load("res://src/data/towers/tar_trap.tres"),
		"displacer": load("res://src/data/towers/displacer.tres"),
		"freeze_trap": load("res://src/data/towers/freeze_trap.tres"),
		"corrosive_vapor": load("res://src/data/towers/corrosive_vapor.tres"),
		"artillery": load("res://src/data/towers/artillery.tres"),
		"spike_trap": load("res://src/data/towers/spike_trap.tres"),
		"siphon": load("res://src/data/towers/siphon.tres"),
		"soul_lantern": load("res://src/data/towers/soul_lantern.tres"),
		"sparkler": load("res://src/data/towers/sparkler.tres"),
	}
