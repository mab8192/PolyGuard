class_name WaveManager extends Node

var stage: Stage

var wave: int = 0
var current_wave: WaveData
var stage_time: float = 0.0
var is_stage_active: bool = true
var wave_is_active: bool = false
var spawners: Array[Spawner] = []

func setup(p_stage: Stage) -> void:
	stage = p_stage
	
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_exit.connect(_on_enemy_exit)
	SignalBus.wave_started.connect(_on_wave_started)
	
	SignalBus.stage_loaded.emit()
	SignalBus.stage_time_changed.emit("00:00")

func _process(delta: float) -> void:
	if wave_is_active:
		stage_time += delta
		var total_secs = int(stage_time)
		var mins = total_secs / 60
		var secs = total_secs % 60
		SignalBus.stage_time_changed.emit("%02d:%02d" % [mins, secs])

func start_next_wave() -> void:
	if not stage or not stage.data:
		return
		
	var wave_data: WaveData = stage.data.get_wave(wave)
	if wave_data:
		wave_is_active = true
		current_wave = wave_data
		
		spawners.clear()
		for node in get_tree().get_nodes_in_group("spawners"):
			if node is Spawner:
				spawners.append(node)
		
		# Assign spawn groups to spawners in round-robin fashion and run them
		var spawner_count = spawners.size()
		if spawner_count > 0:
			for i in range(wave_data.spawns.size()):
				var spawn_group = wave_data.spawns[i]
				var spawner = spawners[i % spawner_count]
				spawner.run(spawn_group)
		
		wave += 1
		SignalBus.wave_changed.emit(wave)
		SignalBus.wave_started.emit()
	else:
		printerr("No more waves!")

func _on_wave_started() -> void:
	pass

func _check_wave_completion() -> void:
	var enemies_remaining: int = 0
	if GameManager and GameManager.stage_root and is_instance_valid(GameManager.stage_root.enemies):
		for e in GameManager.stage_root.enemies.get_children():
			if is_instance_valid(e) and !e.is_queued_for_deletion():
				enemies_remaining += 1
	
	if wave_is_active and spawners.all(func(x: Spawner): return !x.is_active()) and enemies_remaining == 0:
		wave_is_active = false
		SignalBus.wave_completed.emit()
		
		if stage:
			stage.add_gold(current_wave.reward_gold)
			var wave_bonus = wave * 250
			stage.add_score(wave_bonus)
		
		if stage and stage.data and wave == stage.data.get_waves().size():
			is_stage_active = false
			var time_bonus = max(0, 5000 - int(stage_time) * 10)
			var lives_bonus = stage.lives * 1000
			stage.add_score(lives_bonus + time_bonus)
			SignalBus.stage_completed.emit()

func _on_enemy_died(enemy: Enemy) -> void:
	if stage:
		stage.add_gold(enemy.data.gold_reward)
		stage.add_score(enemy.data.gold_reward * 10)
	
	_check_wave_completion()

func _on_enemy_exit(enemy: Enemy) -> void:
	if stage:
		stage.take_lives(enemy.data.lives_penalty)

	_check_wave_completion()
