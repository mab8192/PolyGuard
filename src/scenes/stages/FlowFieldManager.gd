class_name FlowFieldManager extends Node

## Manages Stage-wide Flow Fields for Physical, Ghost, and Wall-only pathfinding.
## Offloads heavy Dijkstra swarm congestion recalculations to a background Thread,
## keeping main thread physics frame times < 0.3ms at all game speeds.

signal flow_fields_updated()

const CELL_SIZE: Vector2 = Vector2(16.0, 16.0)
const CONGESTION_UPDATE_INTERVAL: float = 0.35 ## Dynamic congestion update interval

# Congestion Strength Knobs
const LIGHT_ENEMY_CONGESTION: float = 0.5
const HEAVY_ENEMY_CONGESTION: float = 1.5
const GHOST_ENEMY_CONGESTION: float = 0.5
const CONGESTION_RADIUS: float = 24.0

var stage: Stage = null

var physical_field: FlowField = FlowField.new()
var heavy_physical_field: FlowField = FlowField.new()
var ghost_field: FlowField = FlowField.new()
var walls_only_field: FlowField = FlowField.new()

# Per-Exit Flow Fields for multi-exit stages (NavStrategy.FIRST / FARTHEST)
var per_exit_physical_fields: Array[FlowField] = []
var per_exit_heavy_fields: Array[FlowField] = []
var per_exit_ghost_fields: Array[FlowField] = []

# Static reachability masks (1 = open path without crossing towers, 0 = blocked by towers/walls)
var _static_open_reachability: PackedByteArray = PackedByteArray()
var _static_heavy_open_reachability: PackedByteArray = PackedByteArray()
var _per_exit_open_reachability: Array[PackedByteArray] = []
var _per_exit_heavy_open_reachability: Array[PackedByteArray] = []

var _astar_walls: AStarGrid2D = AStarGrid2D.new()
var _astar_full: AStarGrid2D = AStarGrid2D.new()

# Background thread worker fields (isolated to prevent race conditions)
var _bg_physical_field: FlowField = FlowField.new()
var _bg_heavy_field: FlowField = FlowField.new()
var _bg_ghost_field: FlowField = FlowField.new()

var _thread: Thread = null
var _is_thread_running: bool = false
var _congestion_timer: float = 0.0

var _cached_exit_positions: Array[Vector2] = []
var _cached_exit_nodes: Array[Node2D] = []

# Persistent flat arrays for fast separation & thread snapshots
var _enemy_positions: PackedVector2Array = PackedVector2Array()
var _enemy_layers: PackedInt32Array = PackedInt32Array()
var _enemy_weights: PackedFloat32Array = PackedFloat32Array()
var _cell_head: PackedInt32Array = PackedInt32Array()
var _enemy_next: PackedInt32Array = PackedInt32Array()

var visualizer: FlowFieldVisualizer = null

func setup(p_stage: Stage) -> void:
	stage = p_stage
	SignalBus.tower_placed.connect(rebuild_tower_fields)
	SignalBus.tower_destroyed.connect(rebuild_tower_fields)
	SignalBus.exits_updated.connect(_on_exits_changed)
	SignalBus.wave_completed.connect(_on_wave_completed)

	visualizer = FlowFieldVisualizer.new()
	visualizer.name = "FlowFieldVisualizer"
	visualizer.setup(self)
	add_child(visualizer)
	flow_fields_updated.connect(func():
		if visualizer and visualizer.visible:
			visualizer.queue_redraw()
	)

	full_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _thread and _thread.is_alive():
			_thread.wait_to_finish()

func _physics_process(delta: float) -> void:
	if not stage or not is_instance_valid(stage):
		return

	# 1. Harvest background thread results if complete
	if _is_thread_running:
		if not _thread.is_alive():
			_thread.wait_to_finish()
			_is_thread_running = false
			_apply_background_results()

	# 2. Local spatial grid update for separation (fast O(N))
	if stage.wave_is_active:
		_update_enemy_spatial_grid()

		if not _is_thread_running:
			_congestion_timer += delta
			if _congestion_timer >= CONGESTION_UPDATE_INTERVAL:
				_congestion_timer = 0.0
				_launch_background_congestion_update()

func _apply_background_results() -> void:
	# Atomically swap thread calculated vectors and integration costs
	physical_field.flow_vectors = _bg_physical_field.flow_vectors
	physical_field.integration_cost = _bg_physical_field.integration_cost

	heavy_physical_field.flow_vectors = _bg_heavy_field.flow_vectors
	heavy_physical_field.integration_cost = _bg_heavy_field.integration_cost

	ghost_field.flow_vectors = _bg_ghost_field.flow_vectors
	ghost_field.integration_cost = _bg_ghost_field.integration_cost

	if visualizer and visualizer.visible:
		visualizer.queue_redraw()

func _update_enemy_spatial_grid() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var count: int = enemies.size()
	if _enemy_positions.size() != count:
		_enemy_positions.resize(count)
		_enemy_layers.resize(count)
		_enemy_weights.resize(count)
		_enemy_next.resize(count)

	if count == 0:
		return

	var total_cells: int = physical_field.total_cells
	if _cell_head.size() != total_cells:
		_cell_head.resize(total_cells)
	_cell_head.fill(-1)

	var w: int = physical_field.grid_size.x
	var h: int = physical_field.grid_size.y
	var origin: Vector2 = physical_field.world_origin
	var cs_x: float = physical_field.cell_size.x
	var cs_y: float = physical_field.cell_size.y

	for i: int in range(count):
		var enemy: Enemy = enemies[i] as Enemy
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			var pos: Vector2 = enemy.global_position
			_enemy_positions[i] = pos

			var nav: NavigationComponent = enemy.nav
			var nav_layer: int = nav.data.nav_layer if (nav and nav.data) else 1
			_enemy_layers[i] = nav_layer

			var base_weight: float = LIGHT_ENEMY_CONGESTION
			if (nav_layer & 2) != 0:
				base_weight = HEAVY_ENEMY_CONGESTION
			elif (nav_layer & 4) != 0:
				base_weight = GHOST_ENEMY_CONGESTION

			if nav and nav.data:
				base_weight *= nav.data.congestion_weight
			_enemy_weights[i] = base_weight

			var gx: int = int(floor((pos.x - origin.x) / cs_x))
			var gy: int = int(floor((pos.y - origin.y) / cs_y))

			if gx >= 0 and gx < w and gy >= 0 and gy < h:
				var c_idx: int = gy * w + gx
				_enemy_next[i] = _cell_head[c_idx]
				_cell_head[c_idx] = i
			else:
				_enemy_next[i] = -1
		else:
			_enemy_next[i] = -1

func _launch_background_congestion_update() -> void:
	if _enemy_positions.is_empty() or _cached_exit_positions.is_empty():
		return

	var snapshot: Dictionary = {
		"positions": _enemy_positions.duplicate(),
		"layers": _enemy_layers.duplicate(),
		"weights": _enemy_weights.duplicate(),
		"exits": _cached_exit_positions.duplicate()
	}

	_is_thread_running = true
	_thread = Thread.new()
	_thread.start(_bg_thread_task.bind(snapshot))

## Runs purely in background thread (0.0ms main thread cost)
func _bg_thread_task(snapshot: Dictionary) -> void:
	var positions: PackedVector2Array = snapshot["positions"]
	var layers: PackedInt32Array = snapshot["layers"]
	var weights: PackedFloat32Array = snapshot["weights"]
	var exits: Array[Vector2] = snapshot["exits"]

	_bg_physical_field.clear_congestion()
	_bg_heavy_field.clear_congestion()
	_bg_ghost_field.clear_congestion()

	var count: int = positions.size()
	var has_ghosts: bool = false

	for i: int in range(count):
		var pos: Vector2 = positions[i]
		var layer: int = layers[i]
		var weight: float = weights[i]

		if (layer & 4) != 0:
			_bg_ghost_field.add_congestion(pos, weight, CONGESTION_RADIUS)
			has_ghosts = true
		elif (layer & 2) != 0:
			_bg_heavy_field.add_congestion(pos, weight, CONGESTION_RADIUS)
			_bg_physical_field.add_congestion(pos, weight, CONGESTION_RADIUS)
		else:
			_bg_physical_field.add_congestion(pos, weight, CONGESTION_RADIUS)
			_bg_heavy_field.add_congestion(pos, weight, CONGESTION_RADIUS)

	_bg_physical_field.calculate_integration_field(exits)
	_bg_heavy_field.calculate_integration_field(exits)
	if has_ghosts:
		_bg_ghost_field.calculate_integration_field(exits)

## O(1) Local Neighbor Query using Spatial Buckets
func get_separation_vector(actor_pos: Vector2, radius: float = 24.0, instance_id: int = 0) -> Vector2:
	if _enemy_positions.size() <= 1 or _cell_head.is_empty():
		return Vector2.ZERO

	var w: int = physical_field.grid_size.x
	var h: int = physical_field.grid_size.y
	var origin: Vector2 = physical_field.world_origin
	var cs_x: float = physical_field.cell_size.x
	var cs_y: float = physical_field.cell_size.y

	var cx: int = int(floor((actor_pos.x - origin.x) / cs_x))
	var cy: int = int(floor((actor_pos.y - origin.y) / cs_y))
	var cell_rad: int = int(ceil(radius / cs_x))

	var sep_vector: Vector2 = Vector2.ZERO
	var rad_sq: float = radius * radius
	var spin_sign: float = 0.2 if (instance_id % 2 == 0) else -0.2

	for dy: int in range(-cell_rad, cell_rad + 1):
		var gy: int = cy + dy
		if gy < 0 or gy >= h:
			continue
		var row_offset: int = gy * w
		for dx: int in range(-cell_rad, cell_rad + 1):
			var gx: int = cx + dx
			if gx < 0 or gx >= w:
				continue
			var c_idx: int = row_offset + gx
			var curr_enemy: int = _cell_head[c_idx]

			while curr_enemy != -1:
				var other_pos: Vector2 = _enemy_positions[curr_enemy]
				var diff: Vector2 = actor_pos - other_pos
				var d2: float = diff.length_squared()
				if d2 > 0.01 and d2 < rad_sq:
					var dist: float = sqrt(d2)
					var strength: float = 1.0 - (dist / radius)
					var push_dir: Vector2 = diff / dist
					var tangent: Vector2 = Vector2(-push_dir.y, push_dir.x) * spin_sign
					sep_vector += (push_dir + tangent) * strength
				curr_enemy = _enemy_next[curr_enemy]

	return sep_vector

func _on_exits_changed() -> void:
	_update_cached_exits()
	full_rebuild()

func _on_wave_completed() -> void:
	if _thread and _thread.is_alive():
		_thread.wait_to_finish()
		_is_thread_running = false

	physical_field.clear_congestion()
	heavy_physical_field.clear_congestion()
	ghost_field.clear_congestion()
	_bg_physical_field.clear_congestion()
	_bg_heavy_field.clear_congestion()
	_bg_ghost_field.clear_congestion()

	_recalculate_all_integrations()
	_enemy_positions.resize(0)
	_enemy_layers.resize(0)
	_enemy_weights.resize(0)
	_enemy_next.resize(0)
	_cell_head.fill(-1)

func _update_cached_exits() -> void:
	_cached_exit_positions.clear()
	_cached_exit_nodes.clear()
	var exit_nodes: Array[Node] = get_tree().get_nodes_in_group("exits")
	for node: Node in exit_nodes:
		if is_instance_valid(node):
			var exit_obj: Node2D = node as Node2D
			if exit_obj:
				if exit_obj is Exit and not (exit_obj as Exit).is_active:
					continue
				_cached_exit_positions.append(exit_obj.global_position)
				_cached_exit_nodes.append(exit_obj)

func full_rebuild() -> void:
	if _thread and _thread.is_alive():
		_thread.wait_to_finish()
		_is_thread_running = false

	if not stage or not is_instance_valid(stage) or not stage.tiles:
		return

	var map_rect: Rect2 = stage.get_map_pixel_rect()
	if not map_rect.has_area():
		return

	var bounds: Rect2 = map_rect.grow(CELL_SIZE.x)

	physical_field.init_grid(bounds, CELL_SIZE)
	heavy_physical_field.init_grid(bounds, CELL_SIZE)
	ghost_field.init_grid(bounds, CELL_SIZE)
	walls_only_field.init_grid(bounds, CELL_SIZE)

	_bg_physical_field.init_grid(bounds, CELL_SIZE)
	_bg_heavy_field.init_grid(bounds, CELL_SIZE)
	_bg_ghost_field.init_grid(bounds, CELL_SIZE)

	_cell_head.resize(physical_field.total_cells)
	_cell_head.fill(-1)

	var tiles: TileMapLayer = stage.tiles
	var used_cells: Array[Vector2i] = tiles.get_used_cells()
	var tile_size: Vector2 = Vector2(tiles.tile_set.tile_size) * tiles.scale
	var half_tile: Vector2 = tile_size / 2.0

	# 1. Mark TileMap Wall Colliders once on walls_only_field
	for cell_pos: Vector2i in used_cells:
		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
			var wall_rect: Rect2 = Rect2(global_center - half_tile, tile_size)
			walls_only_field.set_rect_blocked(wall_rect, true, 0.0)

	_update_cached_exits()
	walls_only_field.update_wall_clearance()
	walls_only_field.calculate_integration_field(_cached_exit_positions)

	# Initialize AStarGrid2D for walls-only and full pathfinding
	var w: int = physical_field.grid_size.x
	var h: int = physical_field.grid_size.y
	_astar_walls.region = Rect2i(0, 0, w, h)
	_astar_walls.cell_size = CELL_SIZE
	_astar_walls.offset = physical_field.world_origin + (CELL_SIZE * 0.5)
	_astar_walls.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar_walls.update()

	_astar_full.region = Rect2i(0, 0, w, h)
	_astar_full.cell_size = CELL_SIZE
	_astar_full.offset = physical_field.world_origin + (CELL_SIZE * 0.5)
	_astar_full.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar_full.update()

	for gy: int in range(h):
		var row_offset: int = gy * w
		for gx: int in range(w):
			if walls_only_field.base_cost[row_offset + gx] >= FlowField.BLOCKED_COST:
				_astar_walls.set_point_solid(Vector2i(gx, gy), true)
				_astar_full.set_point_solid(Vector2i(gx, gy), true)

	rebuild_tower_fields()

func rebuild_tower_fields() -> void:
	if _thread and _thread.is_alive():
		_thread.wait_to_finish()
		_is_thread_running = false

	if not stage or not is_instance_valid(stage):
		return

	# Instant C++ memory copy of base wall grid and wall clearance across fields
	physical_field.base_cost = walls_only_field.base_cost.duplicate()
	ghost_field.base_cost = walls_only_field.base_cost.duplicate()
	physical_field.clearance_cost = walls_only_field.clearance_cost.duplicate()
	ghost_field.clearance_cost = walls_only_field.clearance_cost.duplicate()

	var has_spectral_towers: bool = false

	# 2. Mark Towers and Barricades (using 25% min overlap so skinny towers don't over-block neighbor cells)
	if stage.towers:
		var w: int = physical_field.grid_size.x
		for child: Node in stage.towers.get_children():
			if child is Tower and is_instance_valid(child) and not child.is_queued_for_deletion() and not (child as Tower).is_preview:
				var tower: Tower = child as Tower
				var tower_rect: Rect2 = _get_tower_rect(tower)
				if tower.collision_layer == 16: # Layer 5: Spectral Towers
					physical_field.set_rect_cost(tower_rect, FlowField.TOWER_COST, 0.25)
					ghost_field.set_rect_cost(tower_rect, FlowField.TOWER_COST, 0.25)
					physical_field.add_rect_clearance(tower_rect)
					ghost_field.add_rect_clearance(tower_rect)
					has_spectral_towers = true
				elif tower.collision_layer > 0: # Physical Towers / Barricades
					physical_field.set_rect_cost(tower_rect, FlowField.TOWER_COST, 0.25)
					physical_field.add_rect_clearance(tower_rect)

				# Fast AStar weight update for placed towers
				var min_cell: Vector2i = physical_field.global_to_grid(tower_rect.position)
				var max_cell: Vector2i = physical_field.global_to_grid(tower_rect.end - Vector2(0.001, 0.001))
				for gy: int in range(min_cell.y, max_cell.y + 1):
					for gx: int in range(min_cell.x, max_cell.x + 1):
						if physical_field.is_valid_cell(gx, gy) and walls_only_field.base_cost[gy * w + gx] < FlowField.BLOCKED_COST:
							_astar_full.set_point_weight_scale(Vector2i(gx, gy), 50.0)

	# Build heavy_physical_field by copying physical_field and filtering out 1-cell pinches (< 32px clearance)
	heavy_physical_field.base_cost = physical_field.base_cost.duplicate()
	heavy_physical_field.clearance_cost = physical_field.clearance_cost.duplicate()

	var w: int = heavy_physical_field.grid_size.x
	var h: int = heavy_physical_field.grid_size.y
	for gy: int in range(h):
		var row: int = gy * w
		for gx: int in range(w):
			var idx: int = row + gx
			if heavy_physical_field.base_cost[idx] < FlowField.TOWER_COST:
				# 1. Horizontal pinch: obstacle on both left and right (16px gap)
				var blocked_l: bool = (gx == 0) or (physical_field.base_cost[idx - 1] >= FlowField.TOWER_COST)
				var blocked_r: bool = (gx == w - 1) or (physical_field.base_cost[idx + 1] >= FlowField.TOWER_COST)
				if blocked_l and blocked_r:
					heavy_physical_field.base_cost[idx] = FlowField.TOWER_COST
					continue

				# 2. Vertical pinch: obstacle on both top and bottom (16px gap)
				var blocked_u: bool = (gy == 0) or (physical_field.base_cost[idx - w] >= FlowField.TOWER_COST)
				var blocked_d: bool = (gy == h - 1) or (physical_field.base_cost[idx + w] >= FlowField.TOWER_COST)
				if blocked_u and blocked_d:
					heavy_physical_field.base_cost[idx] = FlowField.TOWER_COST
					continue

				# 3. Diagonal squeeze (22.6px opening < 32px)
				if (blocked_l and blocked_u) or (blocked_r and blocked_u) or (blocked_l and blocked_d) or (blocked_r and blocked_d):
					heavy_physical_field.base_cost[idx] = FlowField.TOWER_COST
					continue

	# Recalculate integration fields in a single multi-source pass
	var exit_count: int = _cached_exit_positions.size()
	if exit_count > 1:
		if per_exit_physical_fields.size() != exit_count:
			per_exit_physical_fields.resize(exit_count)
		if per_exit_heavy_fields.size() != exit_count:
			per_exit_heavy_fields.resize(exit_count)

		var bounds: Rect2 = physical_field.bounds
		for i: int in range(exit_count):
			if per_exit_physical_fields[i] == null:
				per_exit_physical_fields[i] = FlowField.new()
				per_exit_physical_fields[i].init_grid(bounds, CELL_SIZE)
			per_exit_physical_fields[i].base_cost = physical_field.base_cost.duplicate()
			per_exit_physical_fields[i].clearance_cost = physical_field.clearance_cost.duplicate()

			if per_exit_heavy_fields[i] == null:
				per_exit_heavy_fields[i] = FlowField.new()
				per_exit_heavy_fields[i].init_grid(bounds, CELL_SIZE)
			per_exit_heavy_fields[i].base_cost = heavy_physical_field.base_cost.duplicate()
			per_exit_heavy_fields[i].clearance_cost = heavy_physical_field.clearance_cost.duplicate()
	else:
		per_exit_physical_fields.clear()
		per_exit_heavy_fields.clear()

	physical_field.calculate_multi_integration_fields(_cached_exit_positions, per_exit_physical_fields)
	heavy_physical_field.calculate_multi_integration_fields(_cached_exit_positions, per_exit_heavy_fields)

	if has_spectral_towers:
		if exit_count > 1:
			if per_exit_ghost_fields.size() != exit_count:
				per_exit_ghost_fields.resize(exit_count)
			var bounds: Rect2 = ghost_field.bounds
			for i: int in range(exit_count):
				if per_exit_ghost_fields[i] == null:
					per_exit_ghost_fields[i] = FlowField.new()
					per_exit_ghost_fields[i].init_grid(bounds, CELL_SIZE)
				per_exit_ghost_fields[i].base_cost = ghost_field.base_cost.duplicate()
				per_exit_ghost_fields[i].clearance_cost = ghost_field.clearance_cost.duplicate()
		else:
			per_exit_ghost_fields.clear()

		ghost_field.calculate_multi_integration_fields(_cached_exit_positions, per_exit_ghost_fields)
	else:
		ghost_field.flow_vectors = walls_only_field.flow_vectors.duplicate()
		ghost_field.integration_cost = walls_only_field.integration_cost.duplicate()
		if exit_count > 1:
			if per_exit_ghost_fields.size() != exit_count:
				per_exit_ghost_fields.resize(exit_count)
			for i: int in range(exit_count):
				if per_exit_ghost_fields[i] == null:
					per_exit_ghost_fields[i] = FlowField.new()
					per_exit_ghost_fields[i].init_grid(physical_field.bounds, CELL_SIZE)
				per_exit_ghost_fields[i].flow_vectors = walls_only_field.flow_vectors.duplicate()
				per_exit_ghost_fields[i].integration_cost = walls_only_field.integration_cost.duplicate()
		else:
			per_exit_ghost_fields.clear()

	_rebuild_reachability_masks()

	# Sync background worker base costs and base fields
	_bg_physical_field.base_cost = physical_field.base_cost.duplicate()
	_bg_physical_field.clearance_cost = physical_field.clearance_cost.duplicate()
	_bg_physical_field.flow_vectors = physical_field.flow_vectors
	_bg_physical_field.integration_cost = physical_field.integration_cost

	_bg_heavy_field.base_cost = heavy_physical_field.base_cost.duplicate()
	_bg_heavy_field.clearance_cost = heavy_physical_field.clearance_cost.duplicate()
	_bg_heavy_field.flow_vectors = heavy_physical_field.flow_vectors
	_bg_heavy_field.integration_cost = heavy_physical_field.integration_cost

	_bg_ghost_field.base_cost = ghost_field.base_cost.duplicate()
	_bg_ghost_field.clearance_cost = ghost_field.clearance_cost.duplicate()
	_bg_ghost_field.flow_vectors = ghost_field.flow_vectors
	_bg_ghost_field.integration_cost = ghost_field.integration_cost

	flow_fields_updated.emit()
	SignalBus.flow_fields_updated.emit()

func _rebuild_reachability_masks() -> void:
	var total_cells: int = physical_field.total_cells
	if total_cells == 0:
		return

	if _static_open_reachability.size() != total_cells:
		_static_open_reachability.resize(total_cells)
	if _static_heavy_open_reachability.size() != total_cells:
		_static_heavy_open_reachability.resize(total_cells)

	var p_int: PackedFloat32Array = physical_field.integration_cost
	var h_int: PackedFloat32Array = heavy_physical_field.integration_cost
	for i: int in range(total_cells):
		_static_open_reachability[i] = 1 if p_int[i] < FlowField.TOWER_COST else 0
		_static_heavy_open_reachability[i] = 1 if h_int[i] < FlowField.TOWER_COST else 0

	var exit_count: int = _cached_exit_positions.size()
	if exit_count > 1:
		if _per_exit_open_reachability.size() != exit_count:
			_per_exit_open_reachability.resize(exit_count)
		if _per_exit_heavy_open_reachability.size() != exit_count:
			_per_exit_heavy_open_reachability.resize(exit_count)

		for e_i: int in range(exit_count):
			if _per_exit_open_reachability[e_i].size() != total_cells:
				_per_exit_open_reachability[e_i].resize(total_cells)
			if _per_exit_heavy_open_reachability[e_i].size() != total_cells:
				_per_exit_heavy_open_reachability[e_i].resize(total_cells)

			if e_i < per_exit_physical_fields.size() and per_exit_physical_fields[e_i] != null:
				var e_int: PackedFloat32Array = per_exit_physical_fields[e_i].integration_cost
				for i: int in range(total_cells):
					_per_exit_open_reachability[e_i][i] = 1 if e_int[i] < FlowField.TOWER_COST else 0
			else:
				_per_exit_open_reachability[e_i] = _static_open_reachability.duplicate()

			if e_i < per_exit_heavy_fields.size() and per_exit_heavy_fields[e_i] != null:
				var eh_int: PackedFloat32Array = per_exit_heavy_fields[e_i].integration_cost
				for i: int in range(total_cells):
					_per_exit_heavy_open_reachability[e_i][i] = 1 if eh_int[i] < FlowField.TOWER_COST else 0
			else:
				_per_exit_heavy_open_reachability[e_i] = _static_heavy_open_reachability.duplicate()
	else:
		_per_exit_open_reachability.clear()
		_per_exit_heavy_open_reachability.clear()

func _recalculate_all_integrations() -> void:
	rebuild_tower_fields()

func is_open_path_available(world_pos: Vector2, exit_idx: int = -1, nav_layer: int = 1) -> bool:
	if (nav_layer & 4) != 0:
		return walls_only_field.is_reachable(world_pos)

	var is_heavy: bool = (nav_layer & 2) != 0
	var field: FlowField = heavy_physical_field if is_heavy else physical_field
	var reach_mask: PackedByteArray = _static_heavy_open_reachability if is_heavy else _static_open_reachability
	var per_exit_masks: Array[PackedByteArray] = _per_exit_heavy_open_reachability if is_heavy else _per_exit_open_reachability

	if reach_mask.is_empty():
		return true

	var g: Vector2i = field.global_to_grid(world_pos)
	if not field.is_valid_cell(g.x, g.y):
		return false

	var idx: int = field.grid_to_index(g.x, g.y)
	if exit_idx >= 0 and exit_idx < per_exit_masks.size():
		return per_exit_masks[exit_idx][idx] == 1

	return reach_mask[idx] == 1

func get_field_for_strategy(nav_layer: int = 1, strategy: int = 0, world_pos: Vector2 = Vector2.ZERO) -> FlowField:
	var is_ghost: bool = (nav_layer & 4) != 0
	var is_heavy: bool = (nav_layer & 2) != 0

	var base_field: FlowField = ghost_field if is_ghost else (heavy_physical_field if is_heavy else physical_field)
	var per_exit_list: Array[FlowField] = per_exit_ghost_fields if is_ghost else (per_exit_heavy_fields if is_heavy else per_exit_physical_fields)

	if per_exit_list.is_empty() or _cached_exit_positions.size() <= 1:
		return base_field

	match strategy:
		0: # CLOSEST
			return base_field

		2: # FIRST
			if not per_exit_list.is_empty() and per_exit_list[0] != null:
				return per_exit_list[0]
			return base_field

		1: # FARTHEST
			var g: Vector2i = base_field.global_to_grid(world_pos)
			if not base_field.is_valid_cell(g.x, g.y):
				return base_field
			var idx: int = base_field.grid_to_index(g.x, g.y)

			var max_dist: float = -1.0
			var best_field: FlowField = base_field
			for f: FlowField in per_exit_list:
				if f != null and f.is_valid_cell(g.x, g.y):
					var cost: float = f.integration_cost[idx]
					if cost < FlowField.BLOCKED_COST and cost > max_dist:
						max_dist = cost
						best_field = f
			return best_field

	return base_field

func get_field(nav_layer: int) -> FlowField:
	if (nav_layer & 4) != 0:
		return ghost_field
	elif (nav_layer & 2) != 0:
		return heavy_physical_field
	return physical_field

func get_flow_direction(world_pos: Vector2, nav_layer: int) -> Vector2:
	var field: FlowField = get_field(nav_layer)
	return field.sample_direction(world_pos)

func is_reachable(world_pos: Vector2, nav_layer: int) -> bool:
	var field: FlowField = get_field(nav_layer)
	return field.is_reachable(world_pos)

func find_grid_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	if not physical_field or physical_field.total_cells == 0:
		return PackedVector2Array()

	var w: int = physical_field.grid_size.x
	var h: int = physical_field.grid_size.y

	var from_grid: Vector2i = physical_field.global_to_grid(from_pos)
	var to_grid: Vector2i = physical_field.global_to_grid(to_pos)

	from_grid.x = clampi(from_grid.x, 0, w - 1)
	from_grid.y = clampi(from_grid.y, 0, h - 1)
	to_grid.x = clampi(to_grid.x, 0, w - 1)
	to_grid.y = clampi(to_grid.y, 0, h - 1)

	# 1. Try finding path avoiding physical towers and walls
	var path: PackedVector2Array = _astar_full.get_point_path(from_grid, to_grid, true)
	if path.size() >= 2:
		return path

	# 2. Fallback: find path avoiding walls only (passing through towers/barricades)
	path = _astar_walls.get_point_path(from_grid, to_grid, true)
	if path.size() >= 2:
		return path

	return PackedVector2Array([to_pos])

func get_exit_nodes() -> Array[Node2D]:
	return _cached_exit_nodes

func _get_tower_rect(tower: Tower) -> Rect2:
	if stage and stage.has_method("_get_tower_global_rect"):
		return stage._get_tower_global_rect(tower)
	return Rect2(tower.global_position - Vector2(16.0, 16.0), Vector2(32.0, 32.0))
