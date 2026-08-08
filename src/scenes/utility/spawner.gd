class_name Spawner
extends Area2D

@export_group("References")
## Parent path or node to attach spawned enemies under (keeps scene tree clean)
@export var enemy_container: Node2D
@export var exits: Array[Node2D]
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

signal finished()

# Internal state tracking
var _active_groups: int = 0

func _ready() -> void:
	# Fall back to root level or self if no container assigned
	if not enemy_container:
		enemy_container = get_tree().current_scene

## Spawns a full batch of enemies defined by a SpawnGroup object.
func run(group: SpawnGroup) -> void:
	_active_groups += 1

	# 1. Handle delay before group starts
	if group.delay > 0.0:
		await get_tree().create_timer(group.delay, false).timeout

	# 2. Lookup EnemyData from Registry autoload
	var enemy_data: EnemyData = Registry.get_enemy_data(group.enemy_type)
	if not enemy_data:
		push_error("Spawner: Enemy type '%s' not found in Registry!" % group.enemy_type)
		_active_groups -= 1
		if _active_groups == 0:
			finished.emit()
		return

	# 3. Spawn loop
	for i in range(group.count):
		_instantiate_enemy(enemy_data)
		
		# Wait interval time between spawns (unless it's the last unit)
		if i < group.count - 1 and group.interval > 0.0:
			await get_tree().create_timer(group.interval, false).timeout

	_active_groups -= 1
	if _active_groups == 0:
		finished.emit()

func is_active() -> bool:
	return _active_groups > 0

## Returns a spawn point in global coordinates
func _get_spawn_point() -> Vector2:
	return global_position + Vector2(
		randf_range(-32, 32),
		randf_range(-32, 32)
	)

## Internal helper to instantiate and place the enemy in the scene.
func _instantiate_enemy(enemy_data: EnemyData) -> void:
	var enemy := enemy_data.create()

	if not enemy:
		push_error("Spawner: Failed to instantiate enemy.")
		return

	# Set up required fields
	enemy.global_position = _get_spawn_point()
	
	# Add it to the scene tree
	enemy_container.add_child(enemy)

	# Emit signals for UI, WaveManager, or Audio
	SignalBus.enemy_spawned.emit(enemy)
