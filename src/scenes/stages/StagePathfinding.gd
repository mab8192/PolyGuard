class_name StagePathfinding
extends Node

## ============================================================================
## StagePathfinding
## ----------------------------------------------------------------------------
## Manages stage-level pathfinding, field building, size classification,
## selective tower re-baking, A* tower hunting, and dynamic boid separation.
## Populates and updates named FlowField instances in the global FlowFieldManager.
## ============================================================================

signal flow_fields_updated()

const CELL_SIZE: float = 16.0
const COST_DEFAULT: int = 1
const COST_IMPASSABLE: int = 255
const COST_TOWER: int = 80 ## Cost for crossing player towers / barricades
const TOWER_INTEGRATION_THRESHOLD: int = 750 ## Integration cost above which a route is blocked by towers

# Congestion Weights
const LIGHT_ENEMY_CONGESTION: float = 0.5
const HEAVY_ENEMY_CONGESTION: float = 1.5
const GHOST_ENEMY_CONGESTION: float = 0.5

enum SizeClass {
	SMALL,  ## < 16px (1-cell gap)
	MEDIUM, ## 16px - 32px (2-cell clearance)
	LARGE   ## 32px - 64px (3-4 cell clearance)
}

var stage: Stage = null

# Grid dimensions & base wall template
var grid_width: int = 0
var grid_height: int = 0
var world_origin: Vector2 = Vector2.ZERO
var base_wall_costs: PackedByteArray = PackedByteArray()
var base_wall_clearance: PackedInt32Array = PackedInt32Array()

# Dynamic Congestion Density
var congestion_density: PackedFloat32Array = PackedFloat32Array()

# Spatial grid for fast O(1) neighbor queries & boid separation
var _enemy_positions: PackedVector2Array = PackedVector2Array()
var _enemy_weights: PackedFloat32Array = PackedFloat32Array()
var _cell_head: PackedInt32Array = PackedInt32Array()
var _enemy_next: PackedInt32Array = PackedInt32Array()

# A* Pathfinding for direct tower targeting
var _astar_full: AStarGrid2D = AStarGrid2D.new()
var _astar_walls: AStarGrid2D = AStarGrid2D.new()

# Cached Exits
var cached_exit_positions: Array[Vector2] = []
var cached_exit_nodes: Array[Node2D] = []

# Background thread state
var _thread: Thread = null
var _is_thread_running: bool = false
var _rebuild_pending: bool = false
var _rebuild_pending_sync: bool = false
var _rebuild_pending_ghost: bool = false


func setup(p_stage: Stage) -> void:
	stage = p_stage
	SignalBus.tower_placed.connect(_on_tower_placed)
	SignalBus.tower_destroyed.connect(_on_tower_destroyed)
	SignalBus.exits_updated.connect(_on_exits_changed)
	SignalBus.wave_completed.connect(_on_wave_completed)

	full_rebuild(true)


func _on_tower_placed() -> void:
	var blocks_ghosts: bool = _check_any_placed_tower_blocks_ghosts()
	rebuild_tower_fields(false, blocks_ghosts)


func _on_tower_destroyed() -> void:
	# Always re-bake ghost fields on destruction in case the destroyed tower was spectral
	rebuild_tower_fields(false, true)


func _on_exits_changed() -> void:
	_update_cached_exits()
	full_rebuild(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _thread and _thread.is_alive():
			_thread.wait_to_finish()


func _physics_process(_delta: float) -> void:
	# 1. Harvest background thread results if complete
	if _is_thread_running:
		if _thread and not _thread.is_alive():
			_thread.wait_to_finish()
			_is_thread_running = false
			if _rebuild_pending:
				var is_sync: bool = _rebuild_pending_sync
				var rebuild_ghost: bool = _rebuild_pending_ghost
				_rebuild_pending = false
				_rebuild_pending_sync = false
				_rebuild_pending_ghost = false
				rebuild_tower_fields(is_sync, rebuild_ghost)

	# 2. Local spatial grid and dynamic congestion update
	if stage and is_instance_valid(stage) and stage.wave_is_active:
		_update_enemy_spatial_grid()


## Full Stage Rebuild (Walls, TileMaps, Exits, and all 6 size fields)
func full_rebuild(is_sync: bool = false) -> void:
	if _thread and _thread.is_alive():
		_thread.wait_to_finish()
		_is_thread_running = false

	if not stage or not is_instance_valid(stage) or not stage.tiles:
		return

	var map_rect: Rect2 = stage.get_map_pixel_rect()
	if not map_rect.has_area():
		return

	var bounds: Rect2 = map_rect.grow(CELL_SIZE)
	world_origin = bounds.position
	grid_width = maxi(1, int(ceil(bounds.size.x / CELL_SIZE)))
	grid_height = maxi(1, int(ceil(bounds.size.y / CELL_SIZE)))
	var total_cells: int = grid_width * grid_height

	base_wall_costs.resize(total_cells)
	base_wall_costs.fill(COST_DEFAULT)

	base_wall_clearance.resize(total_cells)
	base_wall_clearance.fill(0)

	# 1. Mark TileMap Wall Colliders into base_wall_costs
	var tiles: TileMapLayer = stage.tiles
	var used_cells: Array[Vector2i] = tiles.get_used_cells()
	var tile_size: Vector2 = Vector2(tiles.tile_set.tile_size) * tiles.scale
	var half_tile: Vector2 = tile_size / 2.0

	for cell_pos: Vector2i in used_cells:
		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
			var wall_rect: Rect2 = Rect2(global_center - half_tile, tile_size)
			_set_rect_cost_in_buffer(base_wall_costs, wall_rect, COST_IMPASSABLE)

	# 2. Compute Wall Clearance
	_compute_wall_clearance_buffer()

	# 3. Setup AStar grids
	_setup_astar_grids()

	# 4. Cache exits
	_update_cached_exits()

	# 5. Initialize or reset fields in FlowFieldManager
	FlowFieldManager.create_field("physical_small", grid_width, grid_height, CELL_SIZE, world_origin)
	FlowFieldManager.create_field("physical_medium", grid_width, grid_height, CELL_SIZE, world_origin)
	FlowFieldManager.create_field("physical_large", grid_width, grid_height, CELL_SIZE, world_origin)

	FlowFieldManager.create_field("ghost_small", grid_width, grid_height, CELL_SIZE, world_origin)
	FlowFieldManager.create_field("ghost_medium", grid_width, grid_height, CELL_SIZE, world_origin)
	FlowFieldManager.create_field("ghost_large", grid_width, grid_height, CELL_SIZE, world_origin)

	if cached_exit_positions.size() > 1:
		for e_i: int in range(cached_exit_positions.size()):
			FlowFieldManager.create_field("physical_small_%d" % e_i, grid_width, grid_height, CELL_SIZE, world_origin)
			FlowFieldManager.create_field("physical_medium_%d" % e_i, grid_width, grid_height, CELL_SIZE, world_origin)
			FlowFieldManager.create_field("physical_large_%d" % e_i, grid_width, grid_height, CELL_SIZE, world_origin)
			FlowFieldManager.create_field("ghost_small_%d" % e_i, grid_width, grid_height, CELL_SIZE, world_origin)
			FlowFieldManager.create_field("ghost_medium_%d" % e_i, grid_width, grid_height, CELL_SIZE, world_origin)
			FlowFieldManager.create_field("ghost_large_%d" % e_i, grid_width, grid_height, CELL_SIZE, world_origin)

	_cell_head.resize(total_cells)
	_cell_head.fill(-1)
	congestion_density.resize(total_cells)
	congestion_density.fill(0.0)

	rebuild_tower_fields(is_sync, true)


## Selective Tower Re-bake (only re-bakes ghost fields if a tower blocks ghosts)
func rebuild_tower_fields(is_sync: bool = false, update_ghost: bool = false) -> void:
	if _thread and _thread.is_alive():
		if is_sync:
			_thread.wait_to_finish()
			_is_thread_running = false
		else:
			_rebuild_pending = true
			_rebuild_pending_sync = is_sync or _rebuild_pending_sync
			_rebuild_pending_ghost = update_ghost or _rebuild_pending_ghost
			return

	if not stage or not is_instance_valid(stage) or grid_width == 0 or grid_height == 0:
		return

	var exit_count: int = cached_exit_positions.size()
	if exit_count == 0:
		return

	var task_data: Dictionary = {
		"width": grid_width,
		"height": grid_height,
		"cell_size": CELL_SIZE,
		"origin": world_origin,
		"base_walls": base_wall_costs.duplicate(),
		"wall_clearance": base_wall_clearance.duplicate(),
		"exits": cached_exit_positions.duplicate(),
		"towers": _gather_tower_data(),
		"update_ghost": update_ghost
	}

	_update_astar_tower_weights(task_data["towers"])

	if is_sync:
		var results: Dictionary = _worker_build_fields(task_data)
		_apply_worker_results(results)
	else:
		_is_thread_running = true
		_thread = Thread.new()
		_thread.start(_worker_thread_task.bind(task_data))


func _worker_thread_task(task_data: Dictionary) -> void:
	var results: Dictionary = _worker_build_fields(task_data)
	call_deferred("_apply_worker_results", results)


## Background Worker Task
static func _worker_build_fields(data: Dictionary) -> Dictionary:
	var w: int = data["width"]
	var h: int = data["height"]
	var cs: float = data["cell_size"]
	var origin: Vector2 = data["origin"]
	var exits: Array[Vector2] = data["exits"]
	var base_walls: PackedByteArray = data["base_walls"]
	var wall_clearance: PackedInt32Array = data["wall_clearance"]
	var tower_data: Array = data["towers"]
	var update_ghost: bool = data["update_ghost"]
	var total_cells: int = w * h
	var exit_count: int = exits.size()

	# 1. Physical Cost Buffer (Base walls + placed towers)
	var phys_small_cost: PackedByteArray = base_walls.duplicate()
	var ghost_small_cost: PackedByteArray = base_walls.duplicate()

	# Mark Towers
	for t: Dictionary in tower_data:
		var rect: Rect2 = t["rect"]
		var is_spectral: bool = t["is_spectral"]
		_set_rect_cost_in_buffer_static(phys_small_cost, rect, COST_TOWER, w, h, cs, origin)
		if is_spectral:
			_set_rect_cost_in_buffer_static(ghost_small_cost, rect, COST_TOWER, w, h, cs, origin)

	# 2. Size Footprint Filtering
	var phys_med_cost: PackedByteArray = _build_size_cost_buffer(phys_small_cost, w, h, 2)
	var phys_large_cost: PackedByteArray = _build_size_cost_buffer(phys_small_cost, w, h, 3)

	var ghost_med_cost: PackedByteArray = _build_size_cost_buffer(ghost_small_cost, w, h, 2) if update_ghost else PackedByteArray()
	var ghost_large_cost: PackedByteArray = _build_size_cost_buffer(ghost_small_cost, w, h, 3) if update_ghost else PackedByteArray()

	# 3. Bake Physical Fields
	var f_phys_small: FlowField = FlowField.new(w, h, cs, origin)
	f_phys_small.cost_field = phys_small_cost
	f_phys_small.set_goals_world(exits)
	f_phys_small.bake()

	var f_phys_med: FlowField = FlowField.new(w, h, cs, origin)
	f_phys_med.cost_field = phys_med_cost
	f_phys_med.set_goals_world(exits)
	f_phys_med.bake()

	var f_phys_large: FlowField = FlowField.new(w, h, cs, origin)
	f_phys_large.cost_field = phys_large_cost
	f_phys_large.set_goals_world(exits)
	f_phys_large.bake()

	# Per-Exit Physical Fields
	var per_exit_phys_small: Array[FlowField] = []
	var per_exit_phys_med: Array[FlowField] = []
	var per_exit_phys_large: Array[FlowField] = []

	if exit_count > 1:
		for e_i: int in range(exit_count):
			var single_goal: Array[Vector2] = [exits[e_i]]

			var pf_s: FlowField = FlowField.new(w, h, cs, origin)
			pf_s.cost_field = phys_small_cost.duplicate()
			pf_s.set_goals_world(single_goal)
			pf_s.bake()
			per_exit_phys_small.append(pf_s)

			var pf_m: FlowField = FlowField.new(w, h, cs, origin)
			pf_m.cost_field = phys_med_cost.duplicate()
			pf_m.set_goals_world(single_goal)
			pf_m.bake()
			per_exit_phys_med.append(pf_m)

			var pf_l: FlowField = FlowField.new(w, h, cs, origin)
			pf_l.cost_field = phys_large_cost.duplicate()
			pf_l.set_goals_world(single_goal)
			pf_l.bake()
			per_exit_phys_large.append(pf_l)

	# 4. Bake Ghost Fields if requested
	var f_ghost_small: FlowField = null
	var f_ghost_med: FlowField = null
	var f_ghost_large: FlowField = null
	var per_exit_gh_small: Array[FlowField] = []
	var per_exit_gh_med: Array[FlowField] = []
	var per_exit_gh_large: Array[FlowField] = []

	if update_ghost:
		f_ghost_small = FlowField.new(w, h, cs, origin)
		f_ghost_small.cost_field = ghost_small_cost
		f_ghost_small.set_goals_world(exits)
		f_ghost_small.bake()

		f_ghost_med = FlowField.new(w, h, cs, origin)
		f_ghost_med.cost_field = ghost_med_cost
		f_ghost_med.set_goals_world(exits)
		f_ghost_med.bake()

		f_ghost_large = FlowField.new(w, h, cs, origin)
		f_ghost_large.cost_field = ghost_large_cost
		f_ghost_large.set_goals_world(exits)
		f_ghost_large.bake()

		if exit_count > 1:
			for e_i: int in range(exit_count):
				var single_goal: Array[Vector2] = [exits[e_i]]

				var gf_s: FlowField = FlowField.new(w, h, cs, origin)
				gf_s.cost_field = ghost_small_cost.duplicate()
				gf_s.set_goals_world(single_goal)
				gf_s.bake()
				per_exit_gh_small.append(gf_s)

				var gf_m: FlowField = FlowField.new(w, h, cs, origin)
				gf_m.cost_field = ghost_med_cost.duplicate()
				gf_m.set_goals_world(single_goal)
				gf_m.bake()
				per_exit_gh_med.append(gf_m)

				var gf_l: FlowField = FlowField.new(w, h, cs, origin)
				gf_l.cost_field = ghost_large_cost.duplicate()
				gf_l.set_goals_world(single_goal)
				gf_l.bake()
				per_exit_gh_large.append(gf_l)

	return {
		"phys_small": f_phys_small,
		"phys_med": f_phys_med,
		"phys_large": f_phys_large,
		"per_exit_phys_small": per_exit_phys_small,
		"per_exit_phys_med": per_exit_phys_med,
		"per_exit_phys_large": per_exit_phys_large,
		"update_ghost": update_ghost,
		"ghost_small": f_ghost_small,
		"ghost_med": f_ghost_med,
		"ghost_large": f_ghost_large,
		"per_exit_ghost_small": per_exit_gh_small,
		"per_exit_ghost_med": per_exit_gh_med,
		"per_exit_ghost_large": per_exit_gh_large
	}


func _apply_worker_results(results: Dictionary) -> void:
	FlowFieldManager.register_field("physical_small", results["phys_small"])
	FlowFieldManager.register_field("physical_medium", results["phys_med"])
	FlowFieldManager.register_field("physical_large", results["phys_large"])

	var p_s: Array[FlowField] = results["per_exit_phys_small"]
	var p_m: Array[FlowField] = results["per_exit_phys_med"]
	var p_l: Array[FlowField] = results["per_exit_phys_large"]

	for i: int in range(p_s.size()):
		FlowFieldManager.register_field("physical_small_%d" % i, p_s[i])
		FlowFieldManager.register_field("physical_medium_%d" % i, p_m[i])
		FlowFieldManager.register_field("physical_large_%d" % i, p_l[i])

	if results["update_ghost"]:
		FlowFieldManager.register_field("ghost_small", results["ghost_small"])
		FlowFieldManager.register_field("ghost_medium", results["ghost_med"])
		FlowFieldManager.register_field("ghost_large", results["ghost_large"])

		var g_s: Array[FlowField] = results["per_exit_ghost_small"]
		var g_m: Array[FlowField] = results["per_exit_ghost_med"]
		var g_l: Array[FlowField] = results["per_exit_ghost_large"]

		for i: int in range(g_s.size()):
			FlowFieldManager.register_field("ghost_small_%d" % i, g_s[i])
			FlowFieldManager.register_field("ghost_medium_%d" % i, g_m[i])
			FlowFieldManager.register_field("ghost_large_%d" % i, g_l[i])

	flow_fields_updated.emit()
	FlowFieldManager.notify_fields_updated()


## Footprint convolution for 2x2 (Medium) or 3x3 (Large) clearances
static func _build_size_cost_buffer(base_cost: PackedByteArray, w: int, h: int, footprint_size: int) -> PackedByteArray:
	var result: PackedByteArray = base_cost.duplicate()
	var offset: int = footprint_size - 1

	for gy: int in range(h):
		var row: int = gy * w
		for gx: int in range(w):
			var idx: int = row + gx
			if result[idx] >= COST_IMPASSABLE:
				continue

			var has_valid_footprint: bool = false

			for oy: int in range(-offset, 1):
				for ox: int in range(-offset, 1):
					var start_x: int = gx + ox
					var start_y: int = gy + oy
					if start_x >= 0 and start_x + footprint_size <= w and start_y >= 0 and start_y + footprint_size <= h:
						var block_valid: bool = true
						for by: int in range(footprint_size):
							for bx: int in range(footprint_size):
								var test_idx: int = (start_y + by) * w + (start_x + bx)
								if base_cost[test_idx] >= COST_TOWER:
									block_valid = false
									break
							if not block_valid:
								break
						if block_valid:
							has_valid_footprint = true
							break
				if has_valid_footprint:
					break

			if not has_valid_footprint:
				if base_cost[idx] < COST_TOWER:
					result[idx] = COST_TOWER

	return result


## -- Size & Strategy Helpers -------------------------------------------------

func get_size_class_for_actor(actor: CharacterBody2D) -> SizeClass:
	if not is_instance_valid(actor):
		return SizeClass.SMALL

	if "data" in actor and actor.data:
		var ed: EnemyData = actor.data as EnemyData
		if ed.display_name == "Citadel":
			return SizeClass.LARGE
		elif ed.display_name in ["Tank", "Heavy", "Heavy Ghost", "Grunt", "Splitter", "Healer", "Booster", "Sniper", "Bomber", "Ghost"]:
			return SizeClass.MEDIUM
		elif ed.display_name in ["Light", "Speeder", "Light Ghost"]:
			return SizeClass.SMALL

	for child in actor.get_children():
		if child is CollisionShape2D and is_instance_valid(child) and child.shape:
			var shape = child.shape
			if shape is CircleShape2D:
				var diam: float = shape.radius * 2.0
				return SizeClass.SMALL if diam < 16.0 else (SizeClass.MEDIUM if diam <= 32.0 else SizeClass.LARGE)
			elif shape is RectangleShape2D:
				var min_dim: float = minf(shape.size.x, shape.size.y)
				return SizeClass.SMALL if min_dim < 16.0 else (SizeClass.MEDIUM if min_dim <= 32.0 else SizeClass.LARGE)

	return SizeClass.SMALL


func get_field_id_for_actor(actor: CharacterBody2D, nav_data: NavigationData, strategy: int = 0) -> String:
	var is_ghost: bool = (nav_data and (nav_data.nav_layer & 4) != 0) or ("data" in actor and actor.data and actor.data.type == EnemyData.EnemyType.GHOST)
	var size_class: SizeClass = get_size_class_for_actor(actor)
	var prefix: String = "ghost" if is_ghost else "physical"
	var size_str: String = "small" if size_class == SizeClass.SMALL else ("medium" if size_class == SizeClass.MEDIUM else "large")

	if cached_exit_positions.size() <= 1 or strategy == 0: # CLOSEST uses unified multi-goal field
		return "%s_%s" % [prefix, size_str]

	if strategy == 2: # FIRST
		var first_id: String = "%s_%s_0" % [prefix, size_str]
		if is_open_path(actor.global_position, first_id):
			return first_id
		# If Exit 0 is blocked, failover to any open exit
		for e_i: int in range(1, cached_exit_positions.size()):
			var test_id: String = "%s_%s_%d" % [prefix, size_str, e_i]
			if is_open_path(actor.global_position, test_id):
				return test_id
		return first_id

	if strategy == 1: # FARTHEST
		var max_dist: int = -1
		var best_open_id: String = ""
		var best_any_id: String = "%s_%s" % [prefix, size_str]
		var max_any_dist: int = -1

		for e_i: int in range(cached_exit_positions.size()):
			var test_id: String = "%s_%s_%d" % [prefix, size_str, e_i]
			var fe: FlowField = FlowFieldManager.get_field(test_id)
			if fe:
				var cost: int = fe.get_integration_at_world(actor.global_position)
				if cost < FlowField.INTEGRATION_MAX:
					if cost > max_any_dist:
						max_any_dist = cost
						best_any_id = test_id
					if is_open_path(actor.global_position, test_id) and cost > max_dist:
						max_dist = cost
						best_open_id = test_id

		if not best_open_id.is_empty():
			return best_open_id
		return best_any_id

	return "%s_%s" % [prefix, size_str]


func is_open_path(world_pos: Vector2, field_id: String) -> bool:
	var phys_field: FlowField = FlowFieldManager.get_field(field_id)
	if not phys_field or not phys_field.is_reachable(world_pos):
		return false
	var ghost_id: String = field_id.replace("physical", "ghost")
	var ghost_field: FlowField = FlowFieldManager.get_field(ghost_id)
	if not ghost_field:
		ghost_field = FlowFieldManager.get_field("ghost_small")
	if ghost_field and ghost_field.is_reachable(world_pos):
		var phys_cost: int = phys_field.get_integration_at_world(world_pos)
		var ghost_cost: int = ghost_field.get_integration_at_world(world_pos)
		return (phys_cost - ghost_cost) < 400
	return true


## -- Direct Tower Hunting (A*) ------------------------------------------------

func find_grid_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	if grid_width == 0 or grid_height == 0:
		return PackedVector2Array([to_pos])

	var from_grid: Vector2i = _world_to_astar_grid(from_pos)
	var to_grid: Vector2i = _world_to_astar_grid(to_pos)

	from_grid.x = clampi(from_grid.x, 0, grid_width - 1)
	from_grid.y = clampi(from_grid.y, 0, grid_height - 1)
	to_grid.x = clampi(to_grid.x, 0, grid_width - 1)
	to_grid.y = clampi(to_grid.y, 0, grid_height - 1)

	var path: PackedVector2Array = _astar_full.get_point_path(from_grid, to_grid, true)
	if path.size() >= 2:
		return path

	path = _astar_walls.get_point_path(from_grid, to_grid, true)
	if path.size() >= 2:
		return path

	return PackedVector2Array([to_pos])


func get_grid_path_distance(from_pos: Vector2, to_pos: Vector2) -> float:
	var path: PackedVector2Array = find_grid_path(from_pos, to_pos)
	if path.size() < 2:
		return from_pos.distance_to(to_pos)
	var total: float = 0.0
	for i: int in range(path.size() - 1):
		total += path[i].distance_to(path[i + 1])
	return total


## -- Congestion & Separation --------------------------------------------------

func get_congestion_avoidance_vector(actor_pos: Vector2, desire_dir: Vector2 = Vector2.ZERO, radius: float = 24.0) -> Vector2:
	if _enemy_positions.size() <= 1 or congestion_density.is_empty() or grid_width == 0:
		return Vector2.ZERO

	var probe_pos: Vector2 = actor_pos
	if desire_dir != Vector2.ZERO:
		probe_pos = actor_pos + desire_dir * minf(radius, 24.0)

	var gx: int = int(floor((probe_pos.x - world_origin.x) / CELL_SIZE))
	var gy: int = int(floor((probe_pos.y - world_origin.y) / CELL_SIZE))

	if gx <= 0 or gx >= grid_width - 1 or gy <= 0 or gy >= grid_height - 1:
		return Vector2.ZERO

	var idx: int = gy * grid_width + gx

	var d_l: float = congestion_density[idx - 1]
	var d_r: float = congestion_density[idx + 1]
	var d_u: float = congestion_density[idx - grid_width]
	var d_d: float = congestion_density[idx + grid_width]

	var d_ul: float = congestion_density[idx - grid_width - 1]
	var d_ur: float = congestion_density[idx - grid_width + 1]
	var d_dl: float = congestion_density[idx + grid_width - 1]
	var d_dr: float = congestion_density[idx + grid_width + 1]

	var total_density: float = d_l + d_r + d_u + d_d + d_ul + d_ur + d_dl + d_dr
	if total_density <= 0.05:
		return Vector2.ZERO

	var grad_x: float = (d_r - d_l) + 0.7071 * ((d_ur + d_dr) - (d_ul + d_dl))
	var grad_y: float = (d_d - d_u) + 0.7071 * ((d_dl + d_dr) - (d_ul + d_ur))

	var grad_len_sq: float = grad_x * grad_x + grad_y * grad_y
	if grad_len_sq > 0.0001:
		var inv_len: float = 1.0 / sqrt(grad_len_sq)
		var repulse_dir: Vector2 = Vector2(-grad_x * inv_len, -grad_y * inv_len)

		if desire_dir != Vector2.ZERO and repulse_dir.dot(desire_dir) < -0.6:
			var perp_l: Vector2 = Vector2(-desire_dir.y, desire_dir.x)
			repulse_dir = perp_l

		var max_d: float = maxf(maxf(d_l, d_r), maxf(d_u, d_d))
		var strength: float = clampf(max_d / 2.5, 0.0, 1.0)
		return repulse_dir * strength

	return Vector2.ZERO


func get_separation_vector(actor_pos: Vector2, radius: float = 24.0, _instance_id: int = 0) -> Vector2:
	if _enemy_positions.size() <= 1 or _cell_head.is_empty() or grid_width == 0:
		return Vector2.ZERO

	var cx: int = int(floor((actor_pos.x - world_origin.x) / CELL_SIZE))
	var cy: int = int(floor((actor_pos.y - world_origin.y) / CELL_SIZE))
	var cell_rad: int = int(ceil(radius / CELL_SIZE))

	var sep_vector: Vector2 = Vector2.ZERO
	var rad_sq: float = radius * radius

	for dy: int in range(-cell_rad, cell_rad + 1):
		var gy: int = cy + dy
		if gy < 0 or gy >= grid_height:
			continue
		var row_offset: int = gy * grid_width
		for dx: int in range(-cell_rad, cell_rad + 1):
			var gx: int = cx + dx
			if gx < 0 or gx >= grid_width:
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
					sep_vector += (diff / dist) * strength
				curr_enemy = _enemy_next[curr_enemy]

	return sep_vector


## -- Internal Helpers --------------------------------------------------------

func _update_enemy_spatial_grid() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var count: int = enemies.size()
	if _enemy_positions.size() != count:
		_enemy_positions.resize(count)
		_enemy_weights.resize(count)
		_enemy_next.resize(count)

	var total_cells: int = grid_width * grid_height
	if total_cells == 0:
		return

	if congestion_density.size() != total_cells:
		congestion_density.resize(total_cells)
	congestion_density.fill(0.0)

	if _cell_head.size() != total_cells:
		_cell_head.resize(total_cells)
	_cell_head.fill(-1)

	if count == 0:
		return

	for i: int in range(count):
		var enemy: Enemy = enemies[i] as Enemy
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			var pos: Vector2 = enemy.global_position
			_enemy_positions[i] = pos

			var nav: NavigationComponent = enemy.nav
			var is_ghost: bool = (nav and nav.data and (nav.data.nav_layer & 4) != 0)
			var base_weight: float = GHOST_ENEMY_CONGESTION if is_ghost else LIGHT_ENEMY_CONGESTION

			if nav and nav.data:
				base_weight *= nav.data.congestion_weight
			_enemy_weights[i] = base_weight

			var gx: int = int(floor((pos.x - world_origin.x) / CELL_SIZE))
			var gy: int = int(floor((pos.y - world_origin.y) / CELL_SIZE))

			if gx >= 0 and gx < grid_width and gy >= 0 and gy < grid_height:
				var c_idx: int = gy * grid_width + gx
				_enemy_next[i] = _cell_head[c_idx]
				_cell_head[c_idx] = i
				congestion_density[c_idx] += base_weight
			else:
				_enemy_next[i] = -1
		else:
			_enemy_next[i] = -1


func _on_wave_completed() -> void:
	if _thread and _thread.is_alive():
		_thread.wait_to_finish()
		_is_thread_running = false

	_rebuild_pending = false
	congestion_density.fill(0.0)
	_enemy_positions.resize(0)
	_enemy_weights.resize(0)
	_enemy_next.resize(0)
	_cell_head.fill(-1)


func _update_cached_exits() -> void:
	cached_exit_positions.clear()
	cached_exit_nodes.clear()
	var exit_nodes: Array[Node] = get_tree().get_nodes_in_group("exits")
	for node: Node in exit_nodes:
		if is_instance_valid(node) and node is Node2D:
			var ex: Node2D = node as Node2D
			if ex is Exit and not (ex as Exit).is_active:
				continue
			cached_exit_positions.append(ex.global_position)
			cached_exit_nodes.append(ex)


func _gather_tower_data() -> Array:
	var result: Array = []
	if stage and stage.towers:
		for child: Node in stage.towers.get_children():
			if child is Tower and is_instance_valid(child) and not child.is_queued_for_deletion() and not (child as Tower).is_preview:
				var tower: Tower = child as Tower
				var rect: Rect2 = _get_tower_rect(tower)
				var is_spectral: bool = _is_tower_spectral(tower)
				result.append({
					"rect": rect,
					"is_spectral": is_spectral
				})
	return result


func _check_any_placed_tower_blocks_ghosts() -> bool:
	if stage and stage.towers:
		for child: Node in stage.towers.get_children():
			if child is Tower and is_instance_valid(child) and not child.is_queued_for_deletion() and not (child as Tower).is_preview:
				if _is_tower_spectral(child as Tower):
					return true
	return false


func _is_tower_spectral(tower: Tower) -> bool:
	if not is_instance_valid(tower):
		return false
	# Layer 5 (bitmask 16) designates Spectral Towers
	if (tower.collision_layer & 16) != 0:
		return true
	if tower.data:
		if (tower.data.collision_layer & 16) != 0:
			return true
		var t_id: String = tower.data.tower_id.to_lower()
		if "spectral" in t_id:
			return true
	return false


func _get_tower_rect(tower: Tower) -> Rect2:
	if stage and stage.has_method("_get_tower_global_rect"):
		return stage._get_tower_global_rect(tower)
	return Rect2(tower.global_position - Vector2(16.0, 16.0), Vector2(32.0, 32.0))


func _set_rect_cost_in_buffer(buf: PackedByteArray, rect: Rect2, cost: int) -> void:
	_set_rect_cost_in_buffer_static(buf, rect, cost, grid_width, grid_height, CELL_SIZE, world_origin)


static func _set_rect_cost_in_buffer_static(buf: PackedByteArray, rect: Rect2, cost: int,
		w: int, h: int, cs: float, origin: Vector2) -> void:
	var min_gx: int = clampi(int(floor((rect.position.x - origin.x) / cs)), 0, w - 1)
	var max_gx: int = clampi(int(floor((rect.end.x - 0.001 - origin.x) / cs)), 0, w - 1)
	var min_gy: int = clampi(int(floor((rect.position.y - origin.y) / cs)), 0, h - 1)
	var max_gy: int = clampi(int(floor((rect.end.y - 0.001 - origin.y) / cs)), 0, h - 1)

	for gy: int in range(min_gy, max_gy + 1):
		var row: int = gy * w
		for gx: int in range(min_gx, max_gx + 1):
			var idx: int = row + gx
			if buf[idx] != COST_IMPASSABLE:
				buf[idx] = cost


func _compute_wall_clearance_buffer() -> void:
	var total: int = grid_width * grid_height
	for i: int in range(total):
		base_wall_clearance[i] = 0 if base_wall_costs[i] == COST_IMPASSABLE else 3

	for gy: int in range(grid_height):
		var row: int = gy * grid_width
		for gx: int in range(grid_width):
			if base_wall_costs[row + gx] == COST_IMPASSABLE:
				for dy: int in range(-2, 3):
					var ny: int = gy + dy
					if ny < 0 or ny >= grid_height:
						continue
					for dx: int in range(-2, 3):
						var nx: int = gx + dx
						if nx < 0 or nx >= grid_width:
							continue
						var n_idx: int = ny * grid_width + nx
						if base_wall_costs[n_idx] != COST_IMPASSABLE:
							var dist: int = maxi(absi(dx), absi(dy))
							base_wall_clearance[n_idx] = mini(base_wall_clearance[n_idx], dist)


func _setup_astar_grids() -> void:
	_astar_walls.region = Rect2i(0, 0, grid_width, grid_height)
	_astar_walls.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	_astar_walls.offset = world_origin + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
	_astar_walls.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar_walls.update()

	_astar_full.region = Rect2i(0, 0, grid_width, grid_height)
	_astar_full.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	_astar_full.offset = world_origin + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
	_astar_full.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar_full.update()

	for gy: int in range(grid_height):
		var row: int = gy * grid_width
		for gx: int in range(grid_width):
			if base_wall_costs[row + gx] == COST_IMPASSABLE:
				_astar_walls.set_point_solid(Vector2i(gx, gy), true)
				_astar_full.set_point_solid(Vector2i(gx, gy), true)


func _update_astar_tower_weights(towers: Array) -> void:
	for gy: int in range(grid_height):
		var row: int = gy * grid_width
		for gx: int in range(grid_width):
			if base_wall_costs[row + gx] != COST_IMPASSABLE:
				_astar_full.set_point_weight_scale(Vector2i(gx, gy), 1.0)

	for t: Dictionary in towers:
		var rect: Rect2 = t["rect"]
		var min_gx: int = clampi(int(floor((rect.position.x - world_origin.x) / CELL_SIZE)), 0, grid_width - 1)
		var max_gx: int = clampi(int(floor((rect.end.x - 0.001 - world_origin.x) / CELL_SIZE)), 0, grid_width - 1)
		var min_gy: int = clampi(int(floor((rect.position.y - world_origin.y) / CELL_SIZE)), 0, grid_height - 1)
		var max_gy: int = clampi(int(floor((rect.end.y - 0.001 - world_origin.y) / CELL_SIZE)), 0, grid_height - 1)

		for gy: int in range(min_gy, max_gy + 1):
			for gx: int in range(min_gx, max_gx + 1):
				if base_wall_costs[gy * grid_width + gx] != COST_IMPASSABLE:
					_astar_full.set_point_weight_scale(Vector2i(gx, gy), 50.0)


func _world_to_astar_grid(pos: Vector2) -> Vector2i:
	var local: Vector2 = (pos - world_origin) / CELL_SIZE
	return Vector2i(int(floor(local.x)), int(floor(local.y)))
