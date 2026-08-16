extends Node

const SAVE_PATH = "user://savegame.json"

const DEFAULT_UNLOCKED_STAGES: Array[String] = ["stage_01", "test_stage"]
const DEFAULT_UNLOCKED_TOWERS: Array[String] = ["archer_tower", "tar_trap"]

var _credits: int = 0
var _unlocked_stages: Array[String] = []
var _stage_records: Dictionary = {} # stage_id -> { "completed": bool, "stars": int, "high_score": int, "cleared_once": bool }
var _unlocked_towers: Array[String] = []
var _tower_levels: Dictionary = {} # tower_id -> int (1 to 5)
var _tower_choices: Dictionary = {} # tower_id -> choice_id (String)
var _unlocked_specializations: Dictionary = {} # tower_id -> Array[String]
var _selected_loadout: Array[String] = []

func _ready() -> void:
	load_save()

func get_selected_loadout() -> Array[String]:
	return _selected_loadout.duplicate()

func set_selected_loadout(tower_ids: Array[String]) -> void:
	_selected_loadout = tower_ids.duplicate()
	save_to_disk()

func get_credits() -> int:
	return _credits

func add_credits(amount: int) -> void:
	if amount <= 0:
		return
	_credits += amount
	SignalBus.credits_changed.emit(_credits)
	save_to_disk()

func deduct_credits(amount: int) -> bool:
	if amount <= 0:
		return true
	if _credits < amount:
		return false
	_credits -= amount
	SignalBus.credits_changed.emit(_credits)
	save_to_disk()
	return true

func is_stage_unlocked(stage_id: String) -> bool:
	if stage_id.is_empty():
		return true
	return _unlocked_stages.has(stage_id)

func unlock_stage(stage_id: String) -> void:
	if stage_id.is_empty() or _unlocked_stages.has(stage_id):
		return
	_unlocked_stages.append(stage_id)
	SignalBus.stage_unlocked.emit(stage_id)
	save_to_disk()

func get_stage_record(stage_id: String) -> Dictionary:
	return _stage_records.get(stage_id, {
		"completed": false,
		"stars": 0,
		"high_score": 0,
		"cleared_once": false
	})

func is_tower_unlocked(tower_id: String) -> bool:
	if tower_id.is_empty():
		return true
	return _unlocked_towers.has(tower_id)

func unlock_tower(tower_id: String, cost: int = 0) -> bool:
	if tower_id.is_empty():
		return false
	if _unlocked_towers.has(tower_id):
		return true
	if cost > 0:
		if not deduct_credits(cost):
			return false
	
	_unlocked_towers.append(tower_id)
	if not _tower_levels.has(tower_id):
		_tower_levels[tower_id] = 1
	
	SignalBus.tower_unlocked.emit(tower_id)
	save_to_disk()
	return true

func get_tower_level(tower_id: String) -> int:
	return _tower_levels.get(tower_id, 1)

func upgrade_tower(tower_id: String, cost: int) -> bool:
	if tower_id.is_empty():
		return false
	var cur_level = get_tower_level(tower_id)
	if cur_level >= 5:
		return false
	if cost > 0 and not deduct_credits(cost):
		return false
	
	var new_level = cur_level + 1
	_tower_levels[tower_id] = new_level
	SignalBus.tower_upgraded.emit(tower_id, new_level)
	save_to_disk()
	return true

func is_specialization_unlocked(tower_id: String, choice_id: String) -> bool:
	if tower_id.is_empty() or choice_id.is_empty():
		return false
	var list = _unlocked_specializations.get(tower_id, [])
	return list.has(choice_id)

func unlock_specialization(tower_id: String, choice_id: String, cost: int) -> bool:
	if tower_id.is_empty() or choice_id.is_empty():
		return false
	if is_specialization_unlocked(tower_id, choice_id):
		return true
	if cost > 0 and not deduct_credits(cost):
		return false
		
	var list: Array = _unlocked_specializations.get(tower_id, [])
	if not list.has(choice_id):
		list.append(choice_id)
	_unlocked_specializations[tower_id] = list
	_tower_choices[tower_id] = choice_id
	
	SignalBus.specialization_unlocked.emit(tower_id, choice_id)
	SignalBus.tower_choice_changed.emit(tower_id, choice_id)
	save_to_disk()
	return true

func get_tower_choice(tower_id: String) -> String:
	return _tower_choices.get(tower_id, "")

func set_tower_choice(tower_id: String, choice_id: String) -> void:
	if choice_id.is_empty() or is_specialization_unlocked(tower_id, choice_id):
		_tower_choices[tower_id] = choice_id
		SignalBus.tower_choice_changed.emit(tower_id, choice_id)
		save_to_disk()

func record_stage_clear(stage_id: String, score: int, lives_left: int, max_lives: int) -> Dictionary:
	var record: Dictionary = get_stage_record(stage_id)
	var is_first_clear: bool = not record.get("cleared_once", false)
	
	# Calculate stars (1 to 3 stars based on remaining lives)
	var stars: int = 1
	if max_lives > 0:
		var life_ratio: float = float(lives_left) / float(max_lives)
		if life_ratio >= 0.99:
			stars = 3
		elif life_ratio >= 0.50:
			stars = 2
		else:
			stars = 1
	
	var prev_stars: int = record.get("stars", 0)
	var new_stars: int = maxi(prev_stars, stars)
	var prev_high_score: int = record.get("high_score", 0)
	var new_high_score: int = maxi(prev_high_score, score)
	
	# Reward calculation
	var base_reward: int = 400 if is_first_clear else 100
	var star_bonus: int = stars * 50
	var total_reward: int = base_reward + star_bonus
	
	add_credits(total_reward)
	
	record["completed"] = true
	record["cleared_once"] = true
	record["stars"] = new_stars
	record["high_score"] = new_high_score
	_stage_records[stage_id] = record
	
	# Unlock next stage in linear sequence
	var next_unlocked_id: String = _get_next_stage_id(stage_id)
	if not next_unlocked_id.is_empty():
		unlock_stage(next_unlocked_id)
	
	save_to_disk()
	
	return {
		"stars": stars,
		"base_reward": base_reward,
		"star_bonus": star_bonus,
		"total_reward": total_reward,
		"is_first_clear": is_first_clear,
		"next_stage_id": next_unlocked_id
	}

func _get_next_stage_id(current_stage_id: String) -> String:
	var all_stages = Registry.get_all_stages()
	for i in range(all_stages.size()):
		var s = all_stages[i]
		if s and s.stage_id == current_stage_id:
			if i + 1 < all_stages.size():
				return all_stages[i + 1].stage_id
			break
	return ""

func save_to_disk() -> void:
	var data = {
		"credits": _credits,
		"unlocked_stages": _unlocked_stages,
		"stage_records": _stage_records,
		"unlocked_towers": _unlocked_towers,
		"tower_levels": _tower_levels,
		"tower_choices": _tower_choices,
		"unlocked_specializations": _unlocked_specializations,
		"selected_loadout": _selected_loadout
	}
	
	var json_str = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()

func load_save() -> void:
	_init_defaults()
	
	if not FileAccess.file_exists(SAVE_PATH):
		save_to_disk()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error != OK:
		printerr("SaveManager: Failed to parse save file: ", json.get_error_message())
		return
	
	var data = json.data
	if not data is Dictionary:
		return
	
	_credits = int(data.get("credits", 0))
	
	var saved_stages = data.get("unlocked_stages", [])
	if saved_stages is Array:
		for s in saved_stages:
			var s_str = str(s)
			if not _unlocked_stages.has(s_str):
				_unlocked_stages.append(s_str)
	
	var saved_records = data.get("stage_records", {})
	if saved_records is Dictionary:
		_stage_records = saved_records
	
	var saved_towers = data.get("unlocked_towers", [])
	if saved_towers is Array:
		for t in saved_towers:
			var t_str = str(t)
			if not _unlocked_towers.has(t_str):
				_unlocked_towers.append(t_str)
				
	var saved_levels = data.get("tower_levels", {})
	if saved_levels is Dictionary:
		for k in saved_levels:
			_tower_levels[str(k)] = int(saved_levels[k])
			
	var saved_choices = data.get("tower_choices", {})
	if saved_choices is Dictionary:
		for k in saved_choices:
			_tower_choices[str(k)] = str(saved_choices[k])

	var saved_specs = data.get("unlocked_specializations", {})
	if saved_specs is Dictionary:
		for k in saved_specs:
			var arr: Array[String] = []
			if saved_specs[k] is Array:
				for item in saved_specs[k]:
					arr.append(str(item))
			_unlocked_specializations[str(k)] = arr

	var saved_loadout = data.get("selected_loadout", [])
	if saved_loadout is Array:
		_selected_loadout.clear()
		for item in saved_loadout:
			_selected_loadout.append(str(item))

func _init_defaults() -> void:
	_credits = 0
	_unlocked_stages = DEFAULT_UNLOCKED_STAGES.duplicate()
	_stage_records = {}
	_unlocked_towers = DEFAULT_UNLOCKED_TOWERS.duplicate()
	_tower_levels = {}
	for t in DEFAULT_UNLOCKED_TOWERS:
		_tower_levels[t] = 1
	_tower_choices = {}
	_unlocked_specializations = {}
	_selected_loadout = DEFAULT_UNLOCKED_TOWERS.duplicate()

# =========================================================================
# DEVELOPER CHEATS API
# =========================================================================

func cheat_add_credits(amount: int = 50000) -> void:
	_credits += amount
	SignalBus.credits_changed.emit(_credits)
	save_to_disk()

func cheat_set_credits(amount: int = 999999) -> void:
	_credits = amount
	SignalBus.credits_changed.emit(_credits)
	save_to_disk()

func cheat_unlock_all_stages() -> void:
	for stage_id in Registry.STAGES:
		if not _unlocked_stages.has(stage_id):
			_unlocked_stages.append(stage_id)
			SignalBus.stage_unlocked.emit(stage_id)
	save_to_disk()

func cheat_complete_all_stages(stars: int = 3) -> void:
	cheat_unlock_all_stages()
	for stage_id in Registry.STAGES:
		_stage_records[stage_id] = {
			"completed": true,
			"stars": stars,
			"high_score": 99999,
			"cleared_once": true
		}
	save_to_disk()

func cheat_unlock_all_towers() -> void:
	for tower_id in Registry.TOWERS:
		if not _unlocked_towers.has(tower_id):
			_unlocked_towers.append(tower_id)
		if not _tower_levels.has(tower_id):
			_tower_levels[tower_id] = 1
		SignalBus.tower_unlocked.emit(tower_id)
	save_to_disk()

func cheat_max_all_towers() -> void:
	cheat_unlock_all_towers()
	for tower_id in Registry.TOWERS:
		_tower_levels[tower_id] = 5
		var t_data = Registry.get_tower_data(tower_id)
		if t_data and not t_data.choices.is_empty():
			var specs: Array[String] = []
			for choice in t_data.choices:
				if choice and not choice.id.is_empty():
					specs.append(choice.id)
			_unlocked_specializations[tower_id] = specs
			if not specs.is_empty():
				_tower_choices[tower_id] = specs[0]
		SignalBus.tower_upgraded.emit(tower_id, 5)
	save_to_disk()

func cheat_reset_save() -> void:
	_init_defaults()
	save_to_disk()
	SignalBus.credits_changed.emit(0)
	for stage in DEFAULT_UNLOCKED_STAGES:
		SignalBus.stage_unlocked.emit(stage)
	for tower in DEFAULT_UNLOCKED_TOWERS:
		SignalBus.tower_unlocked.emit(tower)
