class_name Spawner
extends Node2D

## Emitted when a batch (SpawnGroup) finishes spawning
signal group_completed()

@export_group("References")
## Parent path or node to attach spawned enemies under (keeps scene tree clean)
@export var enemy_container: Node2D
@export var exits: Array[Node2D]

# Internal state tracking
var _active: bool = false

func _ready() -> void:
	# Fall back to root level or self if no container assigned
	if not enemy_container:
		enemy_container = get_tree().current_scene

## Spawns a full batch of enemies defined by a SpawnGroup object.
func run(group: SpawnGroup) -> void:
	if _active:
		push_warning("Spawner: Already processing a spawn group!")
		return

	_active = true

	# 1. Handle delay before group starts
	if group.delay > 0.0:
		await get_tree().create_timer(group.delay).timeout

	# 2. Lookup enemy PackedScene from Registry autoload
	var enemy_scene: PackedScene = load(Registry.ENEMY_MAP.get(group.enemy_type))
	if not enemy_scene:
		push_error("Spawner: Enemy type '%s' not found in Registry!" % group.enemy_type)
		_active = false
		group_completed.emit()
		return

	# 3. Spawn loop
	for i in range(group.count):
		_instantiate_enemy(enemy_scene)
		
		# Wait interval time between spawns (unless it's the last unit)
		if i < group.count - 1 and group.interval > 0.0:
			await get_tree().create_timer(group.interval).timeout

	_active = false
	group_completed.emit()


## Internal helper to instantiate and place the enemy in the scene.
func _instantiate_enemy(enemy_scene: PackedScene) -> void:
	var enemy := enemy_scene.instantiate() as Enemy

	if not enemy:
		push_error("Spawner: Failed to instantiate enemy scene.")
		return

	# Set up required fields
	enemy.target = exits[0]
	enemy.global_position = global_position
	
	# Add it to the scene tree
	enemy_container.add_child(enemy)

	# Emit signals for UI, WaveManager, or Audio
	SignalBus.enemy_spawned.emit(enemy)
