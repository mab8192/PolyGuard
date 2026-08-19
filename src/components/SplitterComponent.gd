class_name SplitterComponent extends Node

var data: SplitterData

var _health: HealthComponent

func _ready() -> void:
	if !data:
		push_error("Missing SplitterData! %s" % get_path())
		return
	
	_health = ComponentUtil.get_component(owner, HealthComponent) as HealthComponent
	if !_health:
		push_error("SplitterComponent requires an attached HealthComponent to function!")
		return
	
	if data.depth < data.max_splits:
		_health.died.connect(split)

## Split the owner into smaller copies of itself
func split() -> void:
	if not data or not is_instance_valid(owner):
		return

	var spawn_pos: Vector2 = owner.global_position
	var spawn_scale: Vector2 = owner.scale * 0.5
	var enemy_data: EnemyData = (owner as Enemy).data if (owner is Enemy) else null
	var split_data: SplitterData = data.duplicate(true)
	var parent_node: Node = GameManager.stage_root.enemies if (GameManager.stage_root and GameManager.stage_root.enemies) else owner.get_parent()

	_spawn_copies.call_deferred(spawn_pos, spawn_scale, enemy_data, split_data, parent_node)

func _spawn_copies(spawn_pos: Vector2, spawn_scale: Vector2, enemy_data: EnemyData, split_data: SplitterData, parent_node: Node) -> void:
	if not is_instance_valid(parent_node):
		if GameManager.stage_root and GameManager.stage_root.enemies:
			parent_node = GameManager.stage_root.enemies
		else:
			return

	for i in range(split_data.number_of_copies):
		var copy: Node2D = null

		if enemy_data:
			copy = enemy_data.create()
		elif is_instance_valid(owner):
			copy = owner.duplicate() as Node2D

		if not copy:
			continue

		copy.global_position = spawn_pos + Vector2(randf_range(-12, 12), randf_range(-12, 12))
		copy.scale = spawn_scale

		var splitter_comp: SplitterComponent = ComponentUtil.get_component(copy, SplitterComponent) as SplitterComponent
		if splitter_comp:
			splitter_comp.data = split_data.duplicate(true) as SplitterData
			splitter_comp.data.depth = split_data.depth + 1

		# Apply stat multipliers to health component if available
		var health_comp: HealthComponent = ComponentUtil.get_component(copy, HealthComponent) as HealthComponent
		if health_comp and health_comp.data:
			health_comp.data.max_health *= split_data.health_multiplier
			health_comp.data.armor *= split_data.armor_multiplier
			health_comp.data.magic_resistance *= split_data.magic_resistance_multiplier

		var attack_comp: AttackComponent = ComponentUtil.get_component(copy, AttackComponent) as AttackComponent
		if attack_comp and attack_comp.data:
			attack_comp.data.damage *= split_data.health_multiplier

		parent_node.add_child(copy)

		if copy is Enemy:
			copy.data.lives_penalty = split_data.lives_penalty_override
			SignalBus.enemy_spawned.emit(copy)
