class_name Spawner
extends Area2D

@export_group("References")
## Parent path or node to attach spawned enemies under (keeps scene tree clean)
@export var enemy_container: Node2D
@export var exits: Array[Node2D]
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Internal state tracking
var _active: bool = false
var _noise: Noise = FastNoiseLite.new()
var spawn_area_size: Vector2

func _ready() -> void:
	# Fall back to root level or self if no container assigned
	if not enemy_container:
		enemy_container = get_tree().current_scene
	
	var rect = collision_shape_2d.shape as RectangleShape2D
	spawn_area_size = Vector2(rect.size.x, rect.size.y)

## Spawns a full batch of enemies defined by a SpawnGroup object.
func run(group: SpawnGroup) -> void:
	if _active:
		push_warning("Spawner: Already processing a spawn group!")
		return

	_active = true

	# 1. Handle delay before group starts
	if group.delay > 0.0:
		await get_tree().create_timer(group.delay, false).timeout

	# 2. Lookup enemy PackedScene from Registry autoload
	var enemy_scene: PackedScene = load(Registry.ENEMY_MAP.get(group.enemy_type))
	if not enemy_scene:
		push_error("Spawner: Enemy type '%s' not found in Registry!" % group.enemy_type)
		_active = false
		return

	# 3. Spawn loop
	for i in range(group.count):
		_instantiate_enemy(enemy_scene)
		
		# Wait interval time between spawns (unless it's the last unit)
		if i < group.count - 1 and group.interval > 0.0:
			await get_tree().create_timer(group.interval, false).timeout

	_active = false

func is_active() -> bool:
	return _active

## Returns a spawn point in global coordinates
func _get_spawn_point() -> Vector2:
	return global_position + Vector2(
		randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
		randf_range(-spawn_area_size.y / 2, spawn_area_size.y / 2)
	)

## Internal helper to instantiate and place the enemy in the scene.
func _instantiate_enemy(enemy_scene: PackedScene) -> void:
	var enemy := enemy_scene.instantiate() as Enemy

	if not enemy:
		push_error("Spawner: Failed to instantiate enemy scene.")
		return

	# Set up required fields
	enemy.global_position = _get_spawn_point()
	
	# Add it to the scene tree
	enemy_container.add_child(enemy)

	# Emit signals for UI, WaveManager, or Audio
	SignalBus.enemy_spawned.emit(enemy)
