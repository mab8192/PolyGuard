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

	for i in range(data.number_of_copies):
		var copy: Node2D = null

		if owner is Enemy and owner.data:
			copy = owner.data.create()
		else:
			copy = owner.duplicate() as Node2D

		if not copy:
			continue

		copy.global_position = owner.global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
		copy.scale = owner.scale * 0.5

		var splitter_comp: SplitterComponent = ComponentUtil.get_component(copy, SplitterComponent) as SplitterComponent
		if splitter_comp:
			if not splitter_comp.data and data:
				splitter_comp.data = data.duplicate(true) as SplitterData
			if splitter_comp.data:
				splitter_comp.data.depth = data.depth + 1

		# Apply stat multipliers to health component if available
		var health_comp: HealthComponent = ComponentUtil.get_component(copy, HealthComponent) as HealthComponent
		if health_comp and health_comp.data:
			health_comp.data.max_health *= data.health_multiplier
			health_comp.data.armor *= data.armor_multiplier
			health_comp.data.magic_resistance *= data.magic_resistance_multiplier

		if GameManager.stage_root and GameManager.stage_root.enemies:
			GameManager.stage_root.enemies.add_child(copy)
		elif owner.get_parent():
			owner.get_parent().add_child(copy)

		if copy is Enemy:
			copy.data.lives_penalty = 1
			SignalBus.enemy_spawned.emit(copy)
