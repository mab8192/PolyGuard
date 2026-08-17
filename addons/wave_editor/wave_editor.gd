@tool
extends Control

const WAVES_DIR := "res://src/data/stages/waves/"
const ENEMIES_DIR := "res://src/data/enemies/"

const COMMON_SPAWNERS: Array[String] = [
	"Spawner",
	"Spawner2",
	"Spawner3",
	"Spawner4"
]

# Discovered dynamically from .tres files in ENEMIES_DIR
var discovered_enemies: Dictionary = {} # id (String) -> EnemyData
var enemy_type_keys: Array[String] = []

var file_selector: OptionButton
var status_label: Label
var stats_label: Label
var warnings_label: Label
var waves_container: VBoxContainer
var scroll_container: ScrollContainer

var current_file_path: String = ""
var current_waves_data: Array = []
var is_loading_ui: bool = false

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_load_enemy_data()

func _ready() -> void:
	_load_enemy_data()
	_build_ui()
	_refresh_file_list()
	if file_selector.item_count > 0:
		_on_file_selected(0)

## Dynamically discovers all EnemyData resources from .tres files
func _load_enemy_data() -> void:
	discovered_enemies.clear()
	enemy_type_keys.clear()

	# 1. Scan res://src/data/enemies/ directory for .tres files
	var dir := DirAccess.open(ENEMIES_DIR)
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.ends_with(".tres"):
				var etype = fname.get_basename()
				var res_path = ENEMIES_DIR.path_join(fname)
				# Use CACHE_MODE_REPLACE to ensure latest values on disk are reloaded
				var res = ResourceLoader.load(res_path, "", ResourceLoader.CACHE_MODE_REPLACE)
				if res and res is EnemyData:
					discovered_enemies[etype] = res
			fname = dir.get_next()
		dir.list_dir_end()

	for k in discovered_enemies:
		enemy_type_keys.append(str(k))
	enemy_type_keys.sort()

func get_enemy_reward(etype: String) -> int:
	if discovered_enemies.has(etype):
		var edata = discovered_enemies[etype] as EnemyData
		if edata:
			return int(edata.energy_reward)
	return 0

func get_enemy_display_name(etype: String) -> String:
	if discovered_enemies.has(etype):
		var edata = discovered_enemies[etype] as EnemyData
		if edata and not edata.display_name.is_empty():
			return edata.display_name
	return etype.capitalize()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root_vbox)

	# 1. Top Toolbar
	var toolbar := HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(toolbar)

	var lbl := Label.new()
	lbl.text = "Wave File:"
	toolbar.add_child(lbl)

	file_selector = OptionButton.new()
	file_selector.custom_minimum_size = Vector2(180, 0)
	file_selector.item_selected.connect(_on_file_selected)
	toolbar.add_child(file_selector)

	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.pressed.connect(_on_reload_pressed)
	toolbar.add_child(reload_btn)

	var save_btn := Button.new()
	save_btn.text = "Save Changes"
	save_btn.pressed.connect(_on_save_pressed)
	toolbar.add_child(save_btn)

	var add_wave_btn := Button.new()
	add_wave_btn.text = "+ Add Wave"
	add_wave_btn.pressed.connect(_on_add_wave_pressed)
	toolbar.add_child(add_wave_btn)

	var validate_btn := Button.new()
	validate_btn.text = "Validate"
	validate_btn.pressed.connect(_on_validate_pressed)
	toolbar.add_child(validate_btn)

	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(status_label)

	# 2. Stage Overview / Stats Banner
	var stats_panel := PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_panel.add_child(stats_vbox)

	stats_label = Label.new()
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_vbox.add_child(stats_label)

	warnings_label = Label.new()
	warnings_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_vbox.add_child(warnings_label)

	# 3. Main Scroll Area for Wave Cards
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll_container)

	waves_container = VBoxContainer.new()
	waves_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	waves_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(waves_container)

func _refresh_file_list() -> void:
	file_selector.clear()
	var dir := DirAccess.open(WAVES_DIR)
	if not dir:
		_set_status("Failed to open directory: %s" % WAVES_DIR, true)
		return

	dir.list_dir_begin()
	var files: Array[String] = []
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	files.sort_custom(func(a: String, b: String) -> bool:
		var a_num = _extract_number(a)
		var b_num = _extract_number(b)
		if a_num != -1 and b_num != -1:
			return a_num < b_num
		if a_num != -1:
			return true
		if b_num != -1:
			return false
		return a < b
	)

	for f in files:
		file_selector.add_item(f)

func _extract_number(s: String) -> int:
	var num_str := ""
	for c in s:
		if c >= "0" and c <= "9":
			num_str += c
	return int(num_str) if num_str != "" else -1

func _on_file_selected(index: int) -> void:
	if index < 0 or index >= file_selector.item_count:
		return
	var filename = file_selector.get_item_text(index)
	current_file_path = WAVES_DIR.path_join(filename)
	_load_file(current_file_path)

func _on_reload_pressed() -> void:
	if not current_file_path.is_empty():
		_load_enemy_data()
		_load_file(current_file_path)
		_set_status("Reloaded enemy .tres resources & %s" % current_file_path.get_file())

func _load_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		_set_status("File not found: %s" % path, true)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		_set_status("JSON Parse Error: %s" % json.get_error_message(), true)
		return

	if json.data is Array:
		current_waves_data = json.data
	else:
		_set_status("Invalid format: expected JSON array", true)
		current_waves_data = []

	_render_waves()
	_update_stats_and_warnings()
	_set_status("Loaded %s (%d waves)" % [path.get_file(), current_waves_data.size()])

func _on_save_pressed() -> void:
	if current_file_path.is_empty():
		_set_status("No file selected", true)
		return

	for i in range(current_waves_data.size()):
		if current_waves_data[i] is Dictionary:
			current_waves_data[i]["wave_number"] = i + 1

	var json_string := JSON.stringify(current_waves_data, "  ")
	var file := FileAccess.open(current_file_path, FileAccess.WRITE)
	if not file:
		_set_status("Failed to open file for writing: %s" % current_file_path, true)
		return

	file.store_string(json_string + "\n")
	file.close()

	_update_stats_and_warnings()
	_set_status("Successfully saved %s!" % current_file_path.get_file())

func _on_add_wave_pressed() -> void:
	var new_wave_num = current_waves_data.size() + 1
	var default_enemy = enemy_type_keys[0] if not enemy_type_keys.is_empty() else "grunt"
	var new_wave = {
		"wave_number": new_wave_num,
		"reward_energy": 250,
		"spawns": [
			{
				"spawner_id": "Spawner",
				"enemy_type": default_enemy,
				"count": 15,
				"interval": 0.8,
				"delay": 0.5
			}
		]
	}
	current_waves_data.append(new_wave)
	_render_waves()
	_update_stats_and_warnings()
	_set_status("Added Wave %d" % new_wave_num)

func _on_validate_pressed() -> void:
	_update_stats_and_warnings()
	if warnings_label.text.is_empty():
		_set_status("Validation passed: All rules and constraints satisfied!")
	else:
		_set_status("Validation warnings found (see warning panel)", true)

func _set_status(msg: String, is_error: bool = false) -> void:
	status_label.text = msg
	status_label.modulate = Color(1.0, 0.4, 0.4) if is_error else Color(0.3, 0.95, 0.7)

func _calculate_wave_kill_energy(wave_dict: Dictionary) -> int:
	var total: int = 0
	for s in wave_dict.get("spawns", []):
		if s is Dictionary:
			var etype = str(s.get("enemy_type", ""))
			var count = int(s.get("count", 0))
			total += get_enemy_reward(etype) * count
	return total

func _update_stats_and_warnings() -> void:
	var counts: Dictionary = {}
	var total_enemies: int = 0
	var total_bonus_energy: int = 0
	var total_kill_energy: int = 0
	var warnings: Array[String] = []

	for i in range(current_waves_data.size()):
		var wave_dict = current_waves_data[i]
		if not (wave_dict is Dictionary):
			continue

		var w_num = wave_dict.get("wave_number", i + 1)
		total_bonus_energy += int(wave_dict.get("reward_energy", 0))

		var spawns: Array = wave_dict.get("spawns", [])
		for s in spawns:
			if not (s is Dictionary):
				continue
			var etype = str(s.get("enemy_type", ""))
			var cnt = int(s.get("count", 0))
			total_enemies += cnt
			total_kill_energy += get_enemy_reward(etype) * cnt
			counts[etype] = counts.get(etype, 0) + cnt

			if not discovered_enemies.has(etype):
				warnings.append("Wave %d: Unknown enemy type '%s' (not found in %s)" % [w_num, etype, ENEMIES_DIR])
			if etype == "splitter" and cnt > 3:
				warnings.append("Wave %d: Splitter count is %d (Must be <= 3)" % [w_num, cnt])
			if etype == "speeder" and cnt > 12:
				warnings.append("Wave %d: Speeder count is %d (Recommended <= 12)" % [w_num, cnt])
			if etype == "sniper" and cnt > 10:
				warnings.append("Wave %d: Sniper count is %d (Recommended <= 10)" % [w_num, cnt])
			if etype == "ghost" and cnt > 15:
				warnings.append("Wave %d: Ghost count is %d (Recommended <= 15)" % [w_num, cnt])
			if etype == "citadel" and cnt > 2:
				warnings.append("Wave %d: Citadel count is %d (Recommended <= 2)" % [w_num, cnt])

	var total_yield = total_bonus_energy + total_kill_energy
	var stats_parts: Array[String] = []
	stats_parts.append("Waves: %d | Total Enemies: %d | Total Energy Yield: %d (Bonus: %d | Kill Bounty: %d)" % [
		current_waves_data.size(),
		total_enemies,
		total_yield,
		total_bonus_energy,
		total_kill_energy
	])
	
	var enemy_parts: Array[String] = []
	for etype in enemy_type_keys:
		if counts.has(etype):
			var dname = get_enemy_display_name(etype)
			var r_each = get_enemy_reward(etype)
			enemy_parts.append("%s (%d⚡): %d" % [dname, r_each, counts[etype]])
	
	# Show any unrecognized enemies that might exist in the data
	for etype in counts:
		if not enemy_type_keys.has(etype):
			enemy_parts.append("%s (unknown): %d" % [etype, counts[etype]])

	if not enemy_parts.is_empty():
		stats_parts.append("Breakdown: " + ", ".join(enemy_parts))

	stats_label.text = "\n".join(stats_parts)

	if warnings.is_empty():
		warnings_label.text = ""
	else:
		warnings_label.text = "⚠️ Warnings:\n- " + "\n- ".join(warnings)
		warnings_label.modulate = Color(1.0, 0.7, 0.2)

func _render_waves() -> void:
	is_loading_ui = true
	for child in waves_container.get_children():
		child.queue_free()

	for i in range(current_waves_data.size()):
		var wave_dict = current_waves_data[i]
		if wave_dict is Dictionary:
			var wave_card = _create_wave_card(i, wave_dict)
			waves_container.add_child(wave_card)

	is_loading_ui = false

func _create_wave_card(wave_index: int, wave_dict: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(main_vbox)

	# --- Wave Header ---
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "Wave %d" % (wave_index + 1)
	header.add_child(title)

	header.add_child(VSeparator.new())

	var reward_lbl := Label.new()
	reward_lbl.text = "Bonus Energy:"
	header.add_child(reward_lbl)

	var reward_spin := SpinBox.new()
	reward_spin.min_value = 0
	reward_spin.max_value = 99999
	reward_spin.step = 10
	reward_spin.value = int(wave_dict.get("reward_energy", 0))
	header.add_child(reward_spin)

	var energy_summary_lbl := Label.new()
	header.add_child(energy_summary_lbl)

	var duration_lbl := Label.new()
	duration_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(duration_lbl)

	var update_wave_header_summary = func() -> void:
		var bonus = int(wave_dict.get("reward_energy", 0))
		var kills = _calculate_wave_kill_energy(wave_dict)
		var total = bonus + kills
		energy_summary_lbl.text = "  Kills: +%d⚡  |  Total: %d⚡" % [kills, total]
		energy_summary_lbl.modulate = Color(0.3, 0.95, 0.75)
		duration_lbl.text = "    Duration: ~%.1fs" % _calculate_wave_duration(wave_dict)

	reward_spin.value_changed.connect(func(val: float) -> void:
		if is_loading_ui: return
		wave_dict["reward_energy"] = int(val)
		update_wave_header_summary.call()
		_update_stats_and_warnings()
	)

	var add_spawn_btn := Button.new()
	add_spawn_btn.text = "+ Add Spawn"
	add_spawn_btn.pressed.connect(func() -> void:
		var spawns: Array = wave_dict.get("spawns", [])
		var default_enemy = enemy_type_keys[0] if not enemy_type_keys.is_empty() else "grunt"
		spawns.append({
			"spawner_id": "Spawner",
			"enemy_type": default_enemy,
			"count": 10,
			"interval": 0.8,
			"delay": 0.0
		})
		wave_dict["spawns"] = spawns
		_render_waves()
		_update_stats_and_warnings()
	)
	header.add_child(add_spawn_btn)

	var dup_wave_btn := Button.new()
	dup_wave_btn.text = "Duplicate"
	dup_wave_btn.pressed.connect(func() -> void:
		var copy = wave_dict.duplicate(true)
		current_waves_data.insert(wave_index + 1, copy)
		_render_waves()
		_update_stats_and_warnings()
	)
	header.add_child(dup_wave_btn)

	var move_up_btn := Button.new()
	move_up_btn.text = "▲"
	move_up_btn.disabled = (wave_index == 0)
	move_up_btn.pressed.connect(func() -> void:
		if wave_index > 0:
			var temp = current_waves_data[wave_index - 1]
			current_waves_data[wave_index - 1] = current_waves_data[wave_index]
			current_waves_data[wave_index] = temp
			_render_waves()
			_update_stats_and_warnings()
	)
	header.add_child(move_up_btn)

	var move_down_btn := Button.new()
	move_down_btn.text = "▼"
	move_down_btn.disabled = (wave_index == current_waves_data.size() - 1)
	move_down_btn.pressed.connect(func() -> void:
		if wave_index < current_waves_data.size() - 1:
			var temp = current_waves_data[wave_index + 1]
			current_waves_data[wave_index + 1] = current_waves_data[wave_index]
			current_waves_data[wave_index] = temp
			_render_waves()
			_update_stats_and_warnings()
	)
	header.add_child(move_down_btn)

	var del_wave_btn := Button.new()
	del_wave_btn.text = "✕ Delete"
	del_wave_btn.pressed.connect(func() -> void:
		current_waves_data.remove_at(wave_index)
		_render_waves()
		_update_stats_and_warnings()
	)
	header.add_child(del_wave_btn)

	update_wave_header_summary.call()

	# --- Spawns Grid Table ---
	var spawns: Array = wave_dict.get("spawns", [])
	if spawns.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "   (No spawn groups in this wave)"
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		main_vbox.add_child(empty_lbl)
	else:
		# Use a 8-column GridContainer so all headers and cells line up with 100% precision
		var grid := GridContainer.new()
		grid.columns = 8
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.add_child(grid)

		# Column Headers
		var h_spw := Label.new()
		h_spw.text = "Spawner ID"
		h_spw.custom_minimum_size = Vector2(130, 0)
		grid.add_child(h_spw)

		var h_type := Label.new()
		h_type.text = "Enemy Type"
		h_type.custom_minimum_size = Vector2(130, 0)
		grid.add_child(h_type)

		var h_cnt := Label.new()
		h_cnt.text = "Count"
		h_cnt.custom_minimum_size = Vector2(80, 0)
		grid.add_child(h_cnt)

		var h_int := Label.new()
		h_int.text = "Interval (s)"
		h_int.custom_minimum_size = Vector2(90, 0)
		grid.add_child(h_int)

		var h_del := Label.new()
		h_del.text = "Delay (s)"
		h_del.custom_minimum_size = Vector2(90, 0)
		grid.add_child(h_del)

		var h_bounty := Label.new()
		h_bounty.text = "Kill Bounty"
		h_bounty.custom_minimum_size = Vector2(120, 0)
		grid.add_child(h_bounty)

		var h_time := Label.new()
		h_time.text = "Timeline Window"
		h_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(h_time)

		var h_act := Label.new()
		h_act.text = "Actions"
		h_act.custom_minimum_size = Vector2(130, 0)
		grid.add_child(h_act)

		for s_idx in range(spawns.size()):
			var spawn_dict = spawns[s_idx]
			if spawn_dict is Dictionary:
				_populate_spawn_grid_row(grid, wave_dict, spawns, s_idx, spawn_dict, update_wave_header_summary)

	return panel

func _populate_spawn_grid_row(grid: GridContainer, wave_dict: Dictionary, spawns: Array, s_idx: int, spawn_dict: Dictionary, update_wave_header_summary: Callable) -> void:
	# 1. Spawner ID (OptionButton)
	var spawner_opt := OptionButton.new()
	spawner_opt.custom_minimum_size = Vector2(130, 0)
	var cur_spw = str(spawn_dict.get("spawner_id", "Spawner"))
	for s_name in COMMON_SPAWNERS:
		spawner_opt.add_item(s_name)
	if not COMMON_SPAWNERS.has(cur_spw):
		spawner_opt.add_item(cur_spw)
	
	for item_idx in range(spawner_opt.item_count):
		if spawner_opt.get_item_text(item_idx) == cur_spw:
			spawner_opt.select(item_idx)
			break

	spawner_opt.item_selected.connect(func(idx: int) -> void:
		if is_loading_ui: return
		spawn_dict["spawner_id"] = spawner_opt.get_item_text(idx)
	)
	grid.add_child(spawner_opt)

	# 2. Enemy Type (Discovered from .tres files)
	var type_opt := OptionButton.new()
	type_opt.custom_minimum_size = Vector2(130, 0)
	var cur_type = str(spawn_dict.get("enemy_type", "grunt"))

	var select_idx = -1
	for item_idx in range(enemy_type_keys.size()):
		var etype = enemy_type_keys[item_idx]
		type_opt.add_item(etype)
		if discovered_enemies.has(etype):
			var edata = discovered_enemies[etype] as EnemyData
			if edata and edata.icon:
				type_opt.set_item_icon(item_idx, edata.icon)
		if etype == cur_type:
			select_idx = item_idx

	if select_idx == -1 and not cur_type.is_empty():
		type_opt.add_item(cur_type)
		select_idx = type_opt.item_count - 1

	if select_idx != -1:
		type_opt.select(select_idx)

	var count_spin := SpinBox.new()
	count_spin.min_value = 1
	count_spin.max_value = 200
	count_spin.step = 1
	count_spin.value = int(spawn_dict.get("count", 1))
	count_spin.custom_minimum_size = Vector2(80, 0)

	var intv_spin := SpinBox.new()
	intv_spin.min_value = 0.05
	intv_spin.max_value = 10.0
	intv_spin.step = 0.05
	intv_spin.value = float(spawn_dict.get("interval", 1.0))
	intv_spin.custom_minimum_size = Vector2(90, 0)

	var del_spin := SpinBox.new()
	del_spin.min_value = 0.0
	del_spin.max_value = 120.0
	del_spin.step = 0.1
	del_spin.value = float(spawn_dict.get("delay", 0.0))
	del_spin.custom_minimum_size = Vector2(90, 0)

	var bounty_lbl := Label.new()
	bounty_lbl.custom_minimum_size = Vector2(120, 0)

	var time_window_lbl := Label.new()
	time_window_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var update_timing_and_bounty = func() -> void:
		var c = int(count_spin.value)
		var iv = float(intv_spin.value)
		var dl = float(del_spin.value)
		var et = str(spawn_dict.get("enemy_type", "grunt"))
		var r_each = get_enemy_reward(et)
		var total_bounty = r_each * c
		bounty_lbl.text = "+%d⚡ (%d ea)" % [total_bounty, r_each]
		bounty_lbl.modulate = Color(0.3, 0.95, 0.75)

		var end_t = dl + (c - 1) * iv if c > 1 else dl
		time_window_lbl.text = "t=%.1fs → %.1fs" % [dl, end_t]
		update_wave_header_summary.call()
		_update_stats_and_warnings()

	type_opt.item_selected.connect(func(idx: int) -> void:
		if is_loading_ui: return
		var chosen_type = type_opt.get_item_text(idx)
		spawn_dict["enemy_type"] = chosen_type
		if chosen_type == "splitter" and count_spin.value > 3:
			count_spin.modulate = Color(1.0, 0.4, 0.4)
		else:
			count_spin.modulate = Color(1.0, 1.0, 1.0)
		update_timing_and_bounty.call()
	)
	grid.add_child(type_opt)

	# 3. Count
	count_spin.value_changed.connect(func(val: float) -> void:
		if is_loading_ui: return
		spawn_dict["count"] = int(val)
		if str(spawn_dict.get("enemy_type")) == "splitter" and int(val) > 3:
			count_spin.modulate = Color(1.0, 0.4, 0.4)
		else:
			count_spin.modulate = Color(1.0, 1.0, 1.0)
		update_timing_and_bounty.call()
	)
	if cur_type == "splitter" and count_spin.value > 3:
		count_spin.modulate = Color(1.0, 0.4, 0.4)
	grid.add_child(count_spin)

	# 4. Interval
	intv_spin.value_changed.connect(func(val: float) -> void:
		if is_loading_ui: return
		spawn_dict["interval"] = round(val * 100.0) / 100.0
		update_timing_and_bounty.call()
	)
	grid.add_child(intv_spin)

	# 5. Delay
	del_spin.value_changed.connect(func(val: float) -> void:
		if is_loading_ui: return
		spawn_dict["delay"] = round(val * 10.0) / 10.0
		update_timing_and_bounty.call()
	)
	grid.add_child(del_spin)

	# 6. Kill Bounty
	grid.add_child(bounty_lbl)

	# 7. Timeline Window Label
	grid.add_child(time_window_lbl)

	# 8. Actions (HBoxContainer)
	var actions_box := HBoxContainer.new()
	actions_box.custom_minimum_size = Vector2(130, 0)
	
	var dup_btn := Button.new()
	dup_btn.text = "Dup"
	dup_btn.pressed.connect(func() -> void:
		var copy = spawn_dict.duplicate(true)
		spawns.insert(s_idx + 1, copy)
		_render_waves()
		_update_stats_and_warnings()
	)
	actions_box.add_child(dup_btn)

	var move_up_btn := Button.new()
	move_up_btn.text = "▲"
	move_up_btn.disabled = (s_idx == 0)
	move_up_btn.pressed.connect(func() -> void:
		if s_idx > 0:
			var temp = spawns[s_idx - 1]
			spawns[s_idx - 1] = spawns[s_idx]
			spawns[s_idx] = temp
			_render_waves()
			_update_stats_and_warnings()
	)
	actions_box.add_child(move_up_btn)

	var move_down_btn := Button.new()
	move_down_btn.text = "▼"
	move_down_btn.disabled = (s_idx == spawns.size() - 1)
	move_down_btn.pressed.connect(func() -> void:
		if s_idx < spawns.size() - 1:
			var temp = spawns[s_idx + 1]
			spawns[s_idx + 1] = spawns[s_idx]
			spawns[s_idx] = temp
			_render_waves()
			_update_stats_and_warnings()
	)
	actions_box.add_child(move_down_btn)

	var del_btn := Button.new()
	del_btn.text = "✕"
	del_btn.pressed.connect(func() -> void:
		spawns.remove_at(s_idx)
		_render_waves()
		_update_stats_and_warnings()
	)
	actions_box.add_child(del_btn)

	grid.add_child(actions_box)

	update_timing_and_bounty.call()

func _calculate_wave_duration(wave_dict: Dictionary) -> float:
	var max_time: float = 0.0
	for s in wave_dict.get("spawns", []):
		if s is Dictionary:
			var cnt = int(s.get("count", 1))
			var intv = float(s.get("interval", 1.0))
			var del = float(s.get("delay", 0.0))
			var end_t = del + (cnt - 1) * intv if cnt > 1 else del
			if end_t > max_time:
				max_time = end_t
	return max_time
