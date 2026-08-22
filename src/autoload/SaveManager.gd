extends Node

const SAVE_PATH = "user://savegame.json"

const DEFAULT_UNLOCKED_STAGES: Array[String] = ["stage_00", "test_stage"]
const DEFAULT_UNLOCKED_TOWERS: Array[String] = ["archer_tower", "tar_trap", "spike_trap"]

var _credits: int = 0
var _unlocked_stages: Array[String] = []
var _stage_records: Dictionary = {} # stage_id -> { "completed": bool, "stars": int, "high_score": int, "cleared_once": bool }
var _endless_records: Dictionary = {} # stage_id -> { "highest_wave": int, "high_score": int }
var _unlocked_towers: Array[String] = []
var _tower_levels: Dictionary = {} # tower_id -> int (1 to 5)
var _tower_choices: Dictionary = {} # tower_id -> choice_id (String)
var _unlocked_specializations: Dictionary = {} # tower_id -> Array[String]
var _selected_loadout: Array[String] = []
var _is_ad_free: bool = false

func _ready() -> void:
	load_save()

func is_ad_free() -> bool:
	return _is_ad_free

func set_ad_free(p_ad_free: bool) -> void:
	if _is_ad_free == p_ad_free:
		return
	_is_ad_free = p_ad_free
	save_to_disk()
	if AdManager and AdManager.has_signal("ads_enabled_changed"):
		AdManager.ads_enabled_changed.emit(AdManager.are_ads_enabled())

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

func is_stage_completed(stage_id: String) -> bool:
	if stage_id.is_empty():
		return true
	var record = get_stage_record(stage_id)
	return record.get("completed", false) or record.get("cleared_once", false)

func is_tower_available(tower_id: String) -> bool:
	if tower_id.is_empty():
		return true
	var tower = Registry.get_tower_data(tower_id)
	if not tower:
		return true
	return tower.is_available()

func is_tower_unlocked(tower_id: String) -> bool:
	if tower_id.is_empty():
		return true
	return _unlocked_towers.has(tower_id)

func unlock_tower(tower_id: String, cost: int = 0, force: bool = false) -> bool:
	if tower_id.is_empty():
		return false
	if _unlocked_towers.has(tower_id):
		return true
	if not force and not is_tower_available(tower_id):
		return false
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
	var newly_earned_stars: int = new_stars - prev_stars
	var prev_high_score: int = record.get("high_score", 0)
	var new_high_score: int = maxi(prev_high_score, score)
	
	# Reward calculation:
	# - First clear: 300 base credits + 100 per star earned (100 to 300)
	# - Repeat clear: 50 base credits (0 for tutorial) + 100 per newly achieved star (0 if already earned)
	var is_tutorial: bool = (stage_id == "stage_00" or stage_id.begins_with("tutorial"))
	var base_reward: int = 300 if is_first_clear else (0 if is_tutorial else 50)
	var star_bonus: int = 0 if (is_tutorial and not is_first_clear) else (newly_earned_stars * 100)
	var total_reward: int = base_reward + star_bonus
	
	if total_reward > 0:
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
	
	# Auto-unlock sparkler tower upon beating stage 2
	if stage_id == "stage_02":
		unlock_tower("sparkler", 0, true)
	
	save_to_disk()
	
	return {
		"stars": stars,
		"new_stars": newly_earned_stars,
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

# =========================================================================
# ENDLESS MODE API
# =========================================================================

func get_endless_record(stage_id: String) -> Dictionary:
	return _endless_records.get(stage_id, {
		"highest_wave": 0,
		"high_score": 0
	})

func record_endless_run(stage_id: String, waves_cleared: int, score: int) -> Dictionary:
	var record: Dictionary = get_endless_record(stage_id)
	var prev_highest_wave: int = record.get("highest_wave", 0)
	var prev_high_score: int = record.get("high_score", 0)
	
	var is_new_wave_record: bool = waves_cleared > prev_highest_wave
	var is_new_score_record: bool = score > prev_high_score
	
	var new_highest_wave: int = maxi(prev_highest_wave, waves_cleared)
	var new_high_score: int = maxi(prev_high_score, score)
	
	# Reward calculation:
	# - Base: 5 credits per wave cleared
	# - Wave record bonus: 15 credits per new wave record achieved
	# - Milestone bonus: 50 credits for reaching wave 10, 20, 30, etc. for first time
	var base_reward: int = waves_cleared * 5
	var new_waves_diff: int = maxi(0, new_highest_wave - prev_highest_wave)
	var wave_record_bonus: int = new_waves_diff * 15
	var milestone_bonus: int = 0
	
	for m in range(10, new_highest_wave + 1, 10):
		if prev_highest_wave < m and new_highest_wave >= m:
			milestone_bonus += 50
			
	var total_reward: int = base_reward + wave_record_bonus + milestone_bonus
	if total_reward > 0:
		add_credits(total_reward)
		
	record["highest_wave"] = new_highest_wave
	record["high_score"] = new_high_score
	_endless_records[stage_id] = record
	
	save_to_disk()
	
	return {
		"waves_cleared": waves_cleared,
		"highest_wave": new_highest_wave,
		"is_new_wave_record": is_new_wave_record,
		"is_new_score_record": is_new_score_record,
		"base_reward": base_reward,
		"wave_record_bonus": wave_record_bonus,
		"milestone_bonus": milestone_bonus,
		"total_reward": total_reward
	}

# =========================================================================
# RESPEC & SPENT CREDITS API
# =========================================================================

func get_tower_spent_credits(tower_id: String) -> int:
	var total: int = 0
	var tower_data = Registry.get_tower_data(tower_id)
	if not tower_data:
		return 0
	
	# Tower unlock cost (only if unlocked and cost > 0 and not a starter tower)
	if is_tower_unlocked(tower_id) and tower_data.unlock_cost > 0 and not DEFAULT_UNLOCKED_TOWERS.has(tower_id):
		total += tower_data.unlock_cost
	
	# Level upgrade costs
	var current_level: int = get_tower_level(tower_id)
	for lvl in range(2, current_level + 1):
		total += tower_data.get_upgrade_cost(lvl)
	
	# Specializations costs
	var unlocked_specs: Array = _unlocked_specializations.get(tower_id, [])
	for spec_id in unlocked_specs:
		var choice = tower_data.get_choice(spec_id)
		if choice:
			total += choice.unlock_cost
		else:
			total += 300
	
	return total

func get_total_spent_credits() -> int:
	var total: int = 0
	var all_towers = Registry.get_all_towers()
	for t in all_towers:
		var t_id = Registry.get_tower_id(t)
		total += get_tower_spent_credits(t_id)
	return total

func respec_tower(tower_id: String, is_free: bool) -> Dictionary:
	var spent := get_tower_spent_credits(tower_id)
	if spent <= 0:
		return {"spent": 0, "refund": 0, "fee": 0}
	
	var refund := spent if is_free else int(floor(float(spent) * 0.90))
	var fee := spent - refund
	
	var tower_data = Registry.get_tower_data(tower_id)
	var should_lock: bool = tower_data != null and tower_data.unlock_cost > 0 and not DEFAULT_UNLOCKED_TOWERS.has(tower_id)
	
	if should_lock:
		_unlocked_towers.erase(tower_id)
		_selected_loadout.erase(tower_id)
		_ensure_valid_loadout()
	
	_tower_levels[tower_id] = 1
	_unlocked_specializations[tower_id] = []
	_tower_choices[tower_id] = ""
	
	if refund > 0:
		add_credits(refund)
	else:
		save_to_disk()
	
	SignalBus.tower_upgraded.emit(tower_id, 1)
	SignalBus.specialization_unlocked.emit(tower_id, "")
	SignalBus.tower_choice_changed.emit(tower_id, "")
	if should_lock:
		SignalBus.tower_unlocked.emit(tower_id)
	
	return {"spent": spent, "refund": refund, "fee": fee}

func respec_all_towers(is_free: bool) -> Dictionary:
	var total_spent := get_total_spent_credits()
	if total_spent <= 0:
		return {"spent": 0, "refund": 0, "fee": 0}
	
	var refund := total_spent if is_free else int(floor(float(total_spent) * 0.90))
	var fee := total_spent - refund
	
	# Relock any unlocked towers that required credit purchase (preserves free/earned towers like sparkler)
	var all_towers = Registry.get_all_towers()
	for t in all_towers:
		var t_id = Registry.get_tower_id(t)
		if t and t.unlock_cost > 0 and not DEFAULT_UNLOCKED_TOWERS.has(t_id):
			if _unlocked_towers.has(t_id):
				_unlocked_towers.erase(t_id)
				SignalBus.tower_unlocked.emit(t_id)
	
	_ensure_valid_loadout()
	
	for t_id in _tower_levels.keys():
		_tower_levels[t_id] = 1
		SignalBus.tower_upgraded.emit(t_id, 1)
		
	for t_id in _unlocked_specializations.keys():
		_unlocked_specializations[t_id] = []
		SignalBus.specialization_unlocked.emit(t_id, "")
		
	for t_id in _tower_choices.keys():
		_tower_choices[t_id] = ""
		SignalBus.tower_choice_changed.emit(t_id, "")
	
	if refund > 0:
		add_credits(refund)
	else:
		save_to_disk()
	
	return {"spent": total_spent, "refund": refund, "fee": fee}

func _ensure_valid_loadout() -> void:
	var valid_loadout: Array[String] = []
	for t_id in _selected_loadout:
		if is_tower_unlocked(t_id) and not valid_loadout.has(t_id):
			valid_loadout.append(t_id)
	
	for t_id in _unlocked_towers:
		if valid_loadout.size() >= 4:
			break
		if not valid_loadout.has(t_id):
			valid_loadout.append(t_id)
	
	_selected_loadout = valid_loadout

func save_to_disk() -> void:
	var data = {
		"credits": _credits,
		"is_ad_free": _is_ad_free,
		"unlocked_stages": _unlocked_stages,
		"stage_records": _stage_records,
		"unlocked_towers": _unlocked_towers,
		"tower_levels": _tower_levels,
		"tower_choices": _tower_choices,
		"unlocked_specializations": _unlocked_specializations,
		"selected_loadout": _selected_loadout,
		"endless_records": _endless_records
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
	_is_ad_free = bool(data.get("is_ad_free", false))
	
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

	var saved_endless = data.get("endless_records", {})
	if saved_endless is Dictionary:
		_endless_records = saved_endless

func _init_defaults() -> void:
	_credits = 0
	_is_ad_free = false
	_unlocked_stages = DEFAULT_UNLOCKED_STAGES.duplicate()
	_stage_records = {}
	_unlocked_towers = DEFAULT_UNLOCKED_TOWERS.duplicate()
	_tower_levels = {}
	for t in DEFAULT_UNLOCKED_TOWERS:
		_tower_levels[t] = 1
	_tower_choices = {}
	_unlocked_specializations = {}
	_selected_loadout = DEFAULT_UNLOCKED_TOWERS.duplicate()
	_endless_records = {}

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

func cheat_set_endless_record(stage_id: String, wave: int = 50, score: int = 500000) -> void:
	_endless_records[stage_id] = {
		"highest_wave": wave,
		"high_score": score
	}
	save_to_disk()

func cheat_reset_save() -> void:
	_init_defaults()
	save_to_disk()
	SignalBus.credits_changed.emit(0)
	for stage in DEFAULT_UNLOCKED_STAGES:
		SignalBus.stage_unlocked.emit(stage)
	for tower in DEFAULT_UNLOCKED_TOWERS:
		SignalBus.tower_unlocked.emit(tower)
