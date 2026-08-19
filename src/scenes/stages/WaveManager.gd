class_name WaveManager extends Node

var stage: Stage

var wave: int = 0
var current_wave: WaveData
var stage_time: float = 0.0
var is_stage_active: bool = true
var wave_is_active: bool = false
var spawners: Array[Spawner] = []
var pending_enemies: int = 0

func setup(p_stage: Stage) -> void:
	stage = p_stage
	pending_enemies = 0
	
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_exit.connect(_on_enemy_exit)
	SignalBus.enemy_spawned.connect(_on_enemy_spawned)
	SignalBus.enemy_split_pending.connect(_on_enemy_split_pending)
	SignalBus.wave_started.connect(_on_wave_started)
	
	# 1. Collect all spawners in the stage
	_refresh_spawners()

	# 2. Set initial is_active states according to wave configuration
	_init_stage_spawners_and_exits()

	# 3. Update preview indicators for Wave 1
	update_upcoming_wave_preview()

	SignalBus.stage_loaded.emit()
	SignalBus.stage_time_changed.emit("00:00")

func _process(delta: float) -> void:
	if wave_is_active:
		stage_time += delta
		var total_secs = int(stage_time)
		@warning_ignore("integer_division")
		var mins = total_secs / 60
		var secs = total_secs % 60
		SignalBus.stage_time_changed.emit("%02d:%02d" % [mins, secs])

func _refresh_spawners() -> void:
	spawners.clear()
	for node in get_tree().get_nodes_in_group("spawners"):
		if node is Spawner:
			spawners.append(node)

func _init_stage_spawners_and_exits() -> void:
	if not stage or not stage.data:
		return

	# Spawners: active if they activate on wave 0, inactive if they activate on wave > 0
	for spawner in spawners:
		var act_wave = stage.data.get_spawner_activation_wave(spawner.spawner_id)
		if act_wave == 0 and spawner.spawner_id != spawner.name:
			act_wave = stage.data.get_spawner_activation_wave(spawner.name)
		spawner.set_active(act_wave == 0, false)

	# Exits: active if they activate on wave 0, inactive if they activate on wave > 0
	for node in get_tree().get_nodes_in_group("exits"):
		if node is Exit:
			var act_wave = stage.data.get_exit_activation_wave(node.exit_id)
			if act_wave == 0 and node.exit_id != node.name:
				act_wave = stage.data.get_exit_activation_wave(node.name)
			node.set_active(act_wave == 0, false)

func update_upcoming_wave_preview() -> void:
	if not stage or not stage.data:
		return

	# Wave 1 (index 0) starts with initial active layout; only show preview badges for later wave activations
	if wave == 0:
		for spawner in spawners:
			spawner.set_indicator(Spawner.IndicatorState.NONE)
		for node in get_tree().get_nodes_in_group("exits"):
			if node is Exit:
				node.set_indicator(Exit.IndicatorState.NONE)
		return

	# 1. Spawner preview indicators
	var activating_spawners = stage.data.get_activating_spawners_for_wave(wave)
	for spawner in spawners:
		var is_activating = activating_spawners.has(spawner.spawner_id) or activating_spawners.has(spawner.name)
		if is_activating:
			spawner.set_indicator(Spawner.IndicatorState.WILL_ACTIVATE)
		else:
			spawner.set_indicator(Spawner.IndicatorState.NONE)

	# 2. Exit preview indicators
	var activating_exits = stage.data.get_activating_exits_for_wave(wave)
	for node in get_tree().get_nodes_in_group("exits"):
		if node is Exit:
			var is_activating = activating_exits.has(node.exit_id) or activating_exits.has(node.name)
			if is_activating:
				node.set_indicator(Exit.IndicatorState.WILL_ACTIVATE)
			else:
				node.set_indicator(Exit.IndicatorState.NONE)

func start_next_wave() -> void:
	if not stage or not stage.data:
		return
		
	var wave_data: WaveData = stage.data.get_wave(wave)
	if wave_data:
		wave_is_active = true
		pending_enemies = 0
		current_wave = wave_data
		
		_refresh_spawners()
		
		# 1. Clear preview indicators during active wave
		for spawner in spawners:
			spawner.set_indicator(Spawner.IndicatorState.NONE)
		for node in get_tree().get_nodes_in_group("exits"):
			if node is Exit:
				node.set_indicator(Exit.IndicatorState.NONE)

		# 2. Activate any spawners or exits scheduled for this wave (with animation)
		var activating_spawners = stage.data.get_activating_spawners_for_wave(wave)
		for spawner in spawners:
			if activating_spawners.has(spawner.spawner_id) or activating_spawners.has(spawner.name):
				spawner.activate(true)

		var activating_exits = stage.data.get_activating_exits_for_wave(wave)
		for node in get_tree().get_nodes_in_group("exits"):
			if node is Exit:
				if activating_exits.has(node.exit_id) or activating_exits.has(node.name):
					node.activate(true)
		
		# 3. Collect active spawners
		var active_spawners: Array[Spawner] = []
		for spawner in spawners:
			if spawner.is_active:
				active_spawners.append(spawner)
		
		# 4. Dispatch spawn groups to targeted spawners or round-robin active spawners
		var unassigned_index: int = 0
		for spawn_group in wave_data.spawns:
			if not spawn_group.spawner_id.is_empty():
				var target = _find_spawner_by_id(spawn_group.spawner_id)
				if target:
					if not target.is_active:
						target.activate(true)
					target.run(spawn_group)
				else:
					push_warning("WaveManager: Spawner ID '%s' not found, falling back to active spawners." % spawn_group.spawner_id)
					if not active_spawners.is_empty():
						active_spawners[unassigned_index % active_spawners.size()].run(spawn_group)
						unassigned_index += 1
			else:
				if not active_spawners.is_empty():
					active_spawners[unassigned_index % active_spawners.size()].run(spawn_group)
					unassigned_index += 1
				elif not spawners.is_empty():
					spawners[unassigned_index % spawners.size()].run(spawn_group)
					unassigned_index += 1
		
		wave += 1
		SignalBus.wave_changed.emit(wave)
		SignalBus.wave_started.emit()
	else:
		printerr("No more waves!")

func _find_spawner_by_id(id_or_name: String) -> Spawner:
	for s in spawners:
		if s.matches_id(id_or_name):
			return s
	return null

func _find_exit_by_id(id_or_name: String) -> Exit:
	for node in get_tree().get_nodes_in_group("exits"):
		if node is Exit and node.matches_id(id_or_name):
			return node
	return null

func _on_wave_started() -> void:
	pass

func _check_wave_completion() -> void:
	var enemies_remaining: int = pending_enemies
	if GameManager and GameManager.stage_root and is_instance_valid(GameManager.stage_root.enemies):
		for e in GameManager.stage_root.enemies.get_children():
			if is_instance_valid(e) and !e.is_queued_for_deletion():
				enemies_remaining += 1
	
	if wave_is_active and spawners.all(func(x: Spawner): return !x.is_spawning()) and enemies_remaining == 0:
		wave_is_active = false
		pending_enemies = 0
		SignalBus.wave_completed.emit()
		
		if stage:
			stage.add_energy(current_wave.reward_energy)
			var wave_bonus = wave * 250
			stage.add_score(wave_bonus)
		
		if stage and stage.data and wave == stage.data.get_waves().size():
			is_stage_active = false
			var time_bonus = max(0, 5000 - int(stage_time) * 10)
			var lives_bonus = stage.lives * 1000
			stage.add_score(lives_bonus + time_bonus)
			var stage_id = stage.data.stage_id if stage and stage.data else ""
			SignalBus.stage_completed.emit(stage_id)
		else:
			# Preview upcoming indicators for the next wave during build phase
			update_upcoming_wave_preview()

func _on_enemy_split_pending(count: int) -> void:
	pending_enemies += count

func _on_enemy_spawned(_enemy: Enemy) -> void:
	if pending_enemies > 0:
		pending_enemies -= 1

func _on_enemy_died(enemy: Enemy) -> void:
	if stage:
		stage.add_energy(enemy.data.energy_reward)
		stage.add_score(enemy.data.energy_reward * 10)
	
	_check_wave_completion()

func _on_enemy_exit(enemy: Enemy) -> void:
	if stage:
		stage.take_lives(enemy.data.lives_penalty)

	_check_wave_completion()
