class_name Spawner
extends Area2D

signal finished()
signal state_changed(is_active: bool)

enum IndicatorState { NONE, INCOMING, WILL_ACTIVATE }

@export_group("Configuration")
## Optional unique ID for wave targeting. Defaults to node name if left empty.
@export var spawner_id: String = ""
## Whether this spawner is active and available to spawn enemies.
@export var is_active: bool = true:
	set(val):
		var changed = (is_active != val)
		is_active = val
		_update_visuals(changed and is_inside_tree())
		state_changed.emit(val)

@export_group("References")
## Specific exits this spawner routes to. If empty, uses all active stage exits.
@export var exits: Array[Node2D] = []

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Internal state tracking
var _active_groups: int = 0
var indicator_state: IndicatorState = IndicatorState.NONE
var _indicator_node: Node2D = null
var _pulse_tween: Tween = null
var _highlight_tween: Tween = null
var path_preview: SpawnerPathPreview = null

const ACTIVE_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_MODULATE: Color = Color(0.48, 0.48, 0.54, 0.75)

func _ready() -> void:
	if spawner_id.is_empty():
		spawner_id = name
	
	path_preview = find_child("PathPreview", false, false) as SpawnerPathPreview
	if not path_preview:
		path_preview = SpawnerPathPreview.new()
		path_preview.name = "PathPreview"
		add_child(path_preview)
		
	_update_visuals(false)
	_update_indicator_ui()

func activate(animate: bool = true) -> void:
	var was_inactive = !is_active
	is_active = true
	if was_inactive and animate:
		play_activation_animation()
	SignalBus.spawners_updated.emit()

func deactivate() -> void:
	is_active = false
	SignalBus.spawners_updated.emit()

func set_active(val: bool, animate: bool = true) -> void:
	if val:
		activate(animate)
	else:
		deactivate()

func play_activation_animation() -> void:
	if not is_inside_tree():
		return
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()

	_highlight_tween = create_tween()
	modulate = Color(2.5, 1.8, 1.8, 1.0)
	scale = Vector2(1.25, 1.25)
	_highlight_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_highlight_tween.parallel().tween_property(self, "modulate", Color(0.8, 0.3, 0.3, 0.9), 0.2)
	_highlight_tween.tween_property(self, "modulate", Color(2.2, 1.6, 1.6, 1.0), 0.2)
	_highlight_tween.tween_property(self, "modulate", ACTIVE_MODULATE, 0.4)

func set_indicator(state: IndicatorState) -> void:
	if indicator_state == state:
		return
	indicator_state = state
	_update_indicator_ui()
	if is_instance_valid(path_preview):
		path_preview.update_preview()

func _update_indicator_ui() -> void:
	if not is_inside_tree():
		return

	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if indicator_state == IndicatorState.NONE:
		if _indicator_node:
			_indicator_node.queue_free()
			_indicator_node = null
		return

	if not _indicator_node:
		_indicator_node = Node2D.new()
		_indicator_node.name = "WaveIndicator"
		_indicator_node.position = Vector2(0, -46)
		add_child(_indicator_node)

	for child in _indicator_node.get_children():
		child.queue_free()

	var badge_panel = PanelContainer.new()
	badge_panel.theme = preload("res://src/misc/theme.tres")
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if indicator_state == IndicatorState.INCOMING or indicator_state == IndicatorState.WILL_ACTIVATE:
		badge_panel.theme_type_variation = &"IncomingBadge"
		label.theme_type_variation = &"IncomingText"
		label.text = "INCOMING"

	badge_panel.add_child(label)
	_indicator_node.add_child(badge_panel)

	# Dynamic centering of badge around (0, 0)
	badge_panel.reset_size()
	var sz = badge_panel.get_combined_minimum_size()
	badge_panel.position = -sz / 2.0

	# Pulse animation
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_indicator_node, "scale", Vector2(1.1, 1.1), 0.45).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_indicator_node, "scale", Vector2(0.95, 0.95), 0.45).set_trans(Tween.TRANS_SINE)

func matches_id(id_or_name: String) -> bool:
	return spawner_id == id_or_name or name == id_or_name

func is_spawning() -> bool:
	return _active_groups > 0

## Backward compatibility helper for WaveManager
func is_running() -> bool:
	return _active_groups > 0

func get_active_exits() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not exits.is_empty():
		for exit in exits:
			if is_instance_valid(exit):
				if exit is Exit:
					if exit.is_active:
						result.append(exit)
				else:
					result.append(exit)
	else:
		for node in get_tree().get_nodes_in_group("exits"):
			if node is Exit:
				if node.is_active:
					result.append(node)
			elif node is Node2D:
				result.append(node)
	return result

func _update_visuals(animate: bool = false) -> void:
	if not is_inside_tree():
		return
	var target_col = ACTIVE_MODULATE if is_active else INACTIVE_MODULATE
	if animate:
		var tween = create_tween()
		tween.tween_property(self, "modulate", target_col, 0.4)
	else:
		modulate = target_col
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", !is_active)

## Spawns a full batch of enemies defined by a SpawnGroup object.
func run(group: SpawnGroup, hp_mult: float = 1.0, speed_mult: float = 1.0, bounty_mult: float = 1.0) -> void:
	_active_groups += 1

	# 1. Handle delay before group starts
	if group.delay > 0.0:
		await get_tree().create_timer(group.delay, false).timeout
		if not is_inside_tree():
			return

	# 2. Lookup EnemyData from Registry autoload
	var enemy_data: EnemyData = Registry.get_enemy_data(group.enemy_type)
	if not enemy_data:
		push_error("Spawner (%s): Enemy type '%s' not found in Registry!" % [name, group.enemy_type])
		_active_groups -= 1
		if _active_groups == 0:
			finished.emit()
		return

	# 3. Spawn loop
	for i in range(group.count):
		_instantiate_enemy(enemy_data, hp_mult, speed_mult, bounty_mult)
		
		# Wait interval time between spawns (unless it's the last unit)
		if i < group.count - 1 and group.interval > 0.0:
			await get_tree().create_timer(group.interval, false).timeout
			if not is_inside_tree():
				return

	_active_groups -= 1
	if _active_groups == 0:
		finished.emit()

## Returns a spawn point in global coordinates
func _get_spawn_point() -> Vector2:
	return global_position + Vector2(
		randf_range(-32, 32),
		randf_range(-32, 32)
	)

## Internal helper to instantiate and place the enemy in the scene.
func _instantiate_enemy(enemy_data: EnemyData, hp_mult: float = 1.0, speed_mult: float = 1.0, bounty_mult: float = 1.0) -> void:
	var enemy := enemy_data.create()

	if not enemy:
		push_error("Spawner: Failed to instantiate enemy.")
		return

	# Apply Endless Mode scaling
	if hp_mult != 1.0 or speed_mult != 1.0 or bounty_mult != 1.0:
		enemy.apply_wave_scaling(hp_mult, speed_mult, bounty_mult)

	# Set up required fields
	enemy.global_position = _get_spawn_point()
	
	# Add it to the scene tree
	if GameManager.stage_root:
		GameManager.stage_root.enemies.add_child(enemy)
	else:
		add_child(enemy)

	# Assign targeted active exits if available
	var active_exits = get_active_exits()
	if not active_exits.is_empty() and enemy.nav:
		enemy.nav.set_exits(active_exits)

	# Emit signals for UI, WaveManager, or Audio
	SignalBus.enemy_spawned.emit(enemy)
