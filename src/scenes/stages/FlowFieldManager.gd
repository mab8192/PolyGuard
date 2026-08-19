class_name FlowFieldManager extends Node

## Manages Stage-wide Flow Fields for Physical, Ghost, and Wall-only pathfinding,
## with macro dynamic congestion integration across active enemy swarms.

signal flow_fields_updated()

const CELL_SIZE: Vector2 = Vector2(32.0, 32.0)
const CONGESTION_UPDATE_INTERVAL: float = 0.35 ## Dynamic Dijkstra re-evaluation at ~3 Hz

# Congestion Strength Knobs (Lower = tighter paths, Higher = more eager to branch out)
const LIGHT_ENEMY_CONGESTION: float = 0.5   ## Base congestion penalty per standard/light enemy
const HEAVY_ENEMY_CONGESTION: float = 1.5   ## Base congestion penalty per heavy/tank enemy
const GHOST_ENEMY_CONGESTION: float = 0.5   ## Base congestion penalty per ghost enemy
const CONGESTION_RADIUS: float = 24.0       ## Radius in pixels each enemy deposits congestion

var stage: Stage = null

var physical_field: FlowField = FlowField.new()
var ghost_field: FlowField = FlowField.new()
var walls_only_field: FlowField = FlowField.new()

var _congestion_timer: float = 0.0
var _cached_exit_positions: Array[Vector2] = []
var _cached_exit_nodes: Array[Node2D] = []

# Persistent flat array for high-speed enemy separation (zero dictionary lookups, zero allocations)
var _enemy_positions: PackedVector2Array = PackedVector2Array()

func setup(p_stage: Stage) -> void:
	stage = p_stage
	SignalBus.tower_placed.connect(rebuild_base_fields)
	SignalBus.tower_destroyed.connect(rebuild_base_fields)
	SignalBus.exits_updated.connect(_on_exits_changed)
	SignalBus.wave_completed.connect(_on_wave_completed)
	rebuild_base_fields()

func _physics_process(delta: float) -> void:
	if not stage or not is_instance_valid(stage):
		return

	if stage.wave_is_active:
		_update_enemy_positions()
		_congestion_timer += delta
		if _congestion_timer >= CONGESTION_UPDATE_INTERVAL:
			_congestion_timer = 0.0
			_update_congestion_and_fields()

func _update_enemy_positions() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = enemies.size()
	if _enemy_positions.size() != count:
		_enemy_positions.resize(count)

	for i in range(count):
		var enemy = enemies[i] as Enemy
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			_enemy_positions[i] = enemy.global_position

func _update_congestion_and_fields() -> void:
	physical_field.clear_congestion()
	ghost_field.clear_congestion()

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var has_ghosts: bool = false
	for enemy_node in enemies:
		var enemy = enemy_node as Enemy
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.is_inside_tree():
			continue

		var nav = enemy.nav
		var nav_layer: int = nav.data.nav_layer if (nav and nav.data) else 1

		var base_weight: float = LIGHT_ENEMY_CONGESTION
		if (nav_layer & 2) != 0:
			base_weight = HEAVY_ENEMY_CONGESTION
		elif (nav_layer & 4) != 0:
			base_weight = GHOST_ENEMY_CONGESTION
			has_ghosts = true

		if nav and nav.data:
			base_weight *= nav.data.congestion_weight

		if (nav_layer & 4) != 0:
			ghost_field.add_congestion(enemy.global_position, base_weight, CONGESTION_RADIUS)
		else:
			physical_field.add_congestion(enemy.global_position, base_weight, CONGESTION_RADIUS)

	physical_field.calculate_integration_field(_cached_exit_positions)
	if has_ghosts:
		ghost_field.calculate_integration_field(_cached_exit_positions)

func get_separation_vector(actor_pos: Vector2, radius: float = 24.0, instance_id: int = 0) -> Vector2:
	var total_enemies = _enemy_positions.size()
	if total_enemies <= 1:
		return Vector2.ZERO

	var sep_vector: Vector2 = Vector2.ZERO
	var rad_sq = radius * radius
	var spin_sign: float = 0.2 if (instance_id % 2 == 0) else -0.2

	for i in range(total_enemies):
		var other_pos = _enemy_positions[i]
		var diff = actor_pos - other_pos
		var d2 = diff.length_squared()
		if d2 > 0.01 and d2 < rad_sq:
			var dist = sqrt(d2)
			var strength = 1.0 - (dist / radius)
			var push_dir = diff / dist
			var tangent = Vector2(-push_dir.y, push_dir.x) * spin_sign
			sep_vector += (push_dir + tangent) * strength

	return sep_vector

func _on_exits_changed() -> void:
	_update_cached_exits()
	rebuild_base_fields()

func _on_wave_completed() -> void:
	physical_field.clear_congestion()
	ghost_field.clear_congestion()
	_recalculate_all_integrations()
	_enemy_positions.resize(0)

func _update_cached_exits() -> void:
	_cached_exit_positions.clear()
	_cached_exit_nodes.clear()
	var exit_nodes = get_tree().get_nodes_in_group("exits")
	for node in exit_nodes:
		if is_instance_valid(node):
			var exit_obj = node as Node2D
			if exit_obj:
				if exit_obj is Exit and not exit_obj.is_active:
					continue
				_cached_exit_positions.append(exit_obj.global_position)
				_cached_exit_nodes.append(exit_obj)

func rebuild_base_fields() -> void:
	if not stage or not is_instance_valid(stage) or not stage.tiles:
		return

	var map_rect = stage.get_map_pixel_rect()
	if not map_rect.has_area():
		return

	var bounds = map_rect.grow(CELL_SIZE.x)

	physical_field.init_grid(bounds, CELL_SIZE)
	ghost_field.init_grid(bounds, CELL_SIZE)
	walls_only_field.init_grid(bounds, CELL_SIZE)

	var tiles = stage.tiles
	var used_cells = tiles.get_used_cells()

	# 1. Mark TileMap Wall Colliders
	for cell_pos in used_cells:
		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
			var half_tile = (Vector2(tiles.tile_set.tile_size) * tiles.scale) / 2.0
			var wall_rect = Rect2(global_center - half_tile, half_tile * 2.0)

			physical_field.set_rect_blocked(wall_rect, true)
			ghost_field.set_rect_blocked(wall_rect, true)
			walls_only_field.set_rect_blocked(wall_rect, true)

	# 2. Mark Towers and Barricades
	if stage.towers:
		for child in stage.towers.get_children():
			if child is Tower and is_instance_valid(child) and not child.is_queued_for_deletion() and not child.is_preview:
				var tower = child as Tower
				var tower_rect = _get_tower_rect(tower)
				if tower.collision_layer == 16: # Layer 5: Spectral Towers
					physical_field.set_rect_blocked(tower_rect, true)
					ghost_field.set_rect_blocked(tower_rect, true)
				elif tower.collision_layer > 0: # Physical Towers / Barricades
					physical_field.set_rect_blocked(tower_rect, true)

	_update_cached_exits()
	_recalculate_all_integrations()
	flow_fields_updated.emit()
	SignalBus.flow_fields_updated.emit()

func _recalculate_all_integrations() -> void:
	physical_field.calculate_integration_field(_cached_exit_positions)
	ghost_field.calculate_integration_field(_cached_exit_positions)
	walls_only_field.calculate_integration_field(_cached_exit_positions)

func get_field(nav_layer: int) -> FlowField:
	if (nav_layer & 4) != 0:
		return ghost_field
	return physical_field

func get_flow_direction(world_pos: Vector2, nav_layer: int) -> Vector2:
	var field = get_field(nav_layer)
	return field.sample_direction(world_pos)

func is_reachable(world_pos: Vector2, nav_layer: int) -> bool:
	var field = get_field(nav_layer)
	return field.is_reachable(world_pos)

func get_exit_nodes() -> Array[Node2D]:
	return _cached_exit_nodes

func _get_tower_rect(tower: Tower) -> Rect2:
	if stage and stage.has_method("_get_tower_global_rect"):
		return stage._get_tower_global_rect(tower)
	return Rect2(tower.global_position - Vector2(16.0, 16.0), Vector2(32.0, 32.0))
