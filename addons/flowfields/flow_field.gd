class_name FlowField
extends RefCounted

## ============================================================================
## FlowField
## ----------------------------------------------------------------------------
## A high-performance, fully statically-typed flow field pathfinding grid for
## Godot 4, suitable for RTS/tower-defense unit movement where many agents share
## precomputed fields.
## ============================================================================

const COST_DEFAULT: int = 1
const COST_IMPASSABLE: int = 10000 ## "Cost" to move through an impassable cell (e.g. a wall)
const INTEGRATION_MAX: int = 2147483647 # sentinel for "unreached" (int32 max)
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1),
]
const NEIGHBOR_DIRS: Array[Vector2] = [
	Vector2(0.0, -1.0),
	Vector2(-1.0, 0.0),
	Vector2(1.0, 0.0),
	Vector2(0.0, 1.0),
	Vector2(-0.70710678, -0.70710678),
	Vector2(0.70710678, -0.70710678),
	Vector2(-0.70710678, 0.70710678),
	Vector2(0.70710678, 0.70710678),
]
const NEIGHBOR_DIST: Array[float] = [
	1.0,
	1.0,
	1.0,
	1.0,
	1.41421356,
	1.41421356,
	1.41421356,
	1.41421356
]

var width: int
var height: int
var cell_size: int
var origin: Vector2 ## The flow field is a rectangle centered at origin
var cost_grid: PackedFloat32Array ## Cost to travel through a given cell
var integration_grid: PackedFloat32Array ## Value of each cell (cost to exit)
var field: PackedVector2Array ## Best direction to travel out of the given cell

var targets: Array[Vector2i] ## Grid cells containing the target

## PUBLIC API

func add_target(world_pos: Vector2) -> void:
	var grid_pos := _world_to_grid(world_pos)
	if _is_in_bounds(grid_pos):
		targets.append(grid_pos)
		cost_grid[_index(grid_pos)] = 0

func query(world_pos: Vector2) -> Vector2:
	var grid_cell := _world_to_grid(world_pos)
	if not _is_in_bounds(grid_cell):
		return Vector2.ZERO
	return field[_index(grid_cell)]

## Set cost for a world point (Vector2), grid cell (Vector2i), world rect (Rect2), or grid rect (Rect2i)
func set_cost(target: Variant, cost: float) -> void:
	if target is Vector2:
		var grid_pos := _world_to_grid(target)
		if _is_in_bounds(grid_pos):
			cost_grid[_index(grid_pos)] = cost
	elif target is Vector2i:
		if _is_in_bounds(target):
			cost_grid[_index(target)] = cost
	elif target is Rect2:
		var top_left := _world_to_grid(target.position)
		var bottom_right := _world_to_grid(target.position + target.size)
		var min_x := clampi(top_left.x, 0, width)
		var max_x := clampi(bottom_right.x, 0, width)
		var min_y := clampi(top_left.y, 0, height)
		var max_y := clampi(bottom_right.y, 0, height)
		for y in range(min_y, max_y):
			for x in range(min_x, max_x):
				cost_grid[_index(Vector2i(x, y))] = cost
	elif target is Rect2i:
		var min_x := clampi(target.position.x, 0, width)
		var max_x := clampi(target.position.x + target.size.x, 0, width)
		var min_y := clampi(target.position.y, 0, height)
		var max_y := clampi(target.position.y + target.size.y, 0, height)
		for y in range(min_y, max_y):
			for x in range(min_x, max_x):
				cost_grid[_index(Vector2i(x, y))] = cost

func set_impassable(target: Variant) -> void:
	set_cost(target, COST_IMPASSABLE)

## Reset cost for a world point (Vector2), grid cell (Vector2i), world rect (Rect2), grid rect (Rect2i), or entire grid if target is null
func reset(target: Variant = null) -> void:
	if target == null:
		cost_grid.fill(COST_DEFAULT)
	else:
		set_cost(target, COST_DEFAULT)

func clear_targets() -> void:
	targets.clear()

## Returns true if the world position is in bounds and can reach at least one target
func is_reachable(world_pos: Vector2) -> bool:
	var grid_cell := _world_to_grid(world_pos)
	if not _is_in_bounds(grid_cell):
		return false
	return integration_grid[_index(grid_cell)] < float(INTEGRATION_MAX)

## Traces a streamline path from start_pos along the flow field
func trace_path(start_pos: Vector2, step_size: float = 16.0, max_steps: int = 300, goal_targets: Array = []) -> PackedVector2Array:
	if not is_reachable(start_pos):
		return PackedVector2Array()

	var path: PackedVector2Array = []
	path.append(start_pos)

	var curr_pos := start_pos
	var goal_positions: Array[Vector2] = []
	for g in goal_targets:
		if g is Vector2:
			goal_positions.append(g)
		elif g is Node2D and is_instance_valid(g):
			goal_positions.append(g.global_position)

	for _step in range(max_steps):
		var arrived := false
		for gp in goal_positions:
			if curr_pos.distance_to(gp) <= step_size:
				path.append(gp)
				arrived = true
				break
		if arrived:
			break

		var grid_pos := _world_to_grid(curr_pos)
		if goal_positions.is_empty() and grid_pos in targets:
			break

		var dir := query(curr_pos)
		if dir.length_squared() < 0.0001:
			break

		var next_pos := curr_pos + dir * step_size
		if next_pos.distance_squared_to(curr_pos) < 0.01:
			break

		path.append(next_pos)
		curr_pos = next_pos

	return path

func rebuild() -> void:
	integration_grid.fill(INTEGRATION_MAX)
	_integrate()
	_calculate_flow()

## PRIVATE FUNCTIONS

func _init(width: int, height: int, cell_size: int, origin: Vector2) -> void:
	self.width = width
	self.height = height
	self.cell_size = cell_size
	self.origin = origin
	
	cost_grid = PackedFloat32Array()
	cost_grid.resize(width * height)
	cost_grid.fill(COST_DEFAULT)
	
	integration_grid = PackedFloat32Array()
	integration_grid.resize(width * height)
	integration_grid.fill(INTEGRATION_MAX)
	
	field = PackedVector2Array()
	field.resize(width * height)
	field.fill(Vector2.ZERO)

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = (world_pos - origin) / cell_size
	return Vector2i(int(floor(local.x)), int(floor(local.y)))

func _is_in_bounds(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < width and grid_pos.y >= 0 and grid_pos.y < height


func _index(idx: Vector2i) -> int:
	return idx.y * width + idx.x

## Compute `integration_grid` from cost_grid
func _integrate() -> void:
	var start := Time.get_ticks_usec()
	
	var queue: Array[int] = []
	for target in targets:
		if not _is_in_bounds(target):
			continue
		var idx: int = _index(target)
		integration_grid[idx] = 0.0
		queue.push_back(idx)
	
	var head: int = 0
	while head < queue.size():
		var curr_idx: int = queue[head]
		head += 1
		
		var curr_cost: float = integration_grid[curr_idx]
		var curr_pos := Vector2i(curr_idx % width, curr_idx / width)
		
		for i in range(8):
			var neighbor_pos := curr_pos + NEIGHBORS[i]
			if not _is_in_bounds(neighbor_pos):
				continue
			
			var n_idx := _index(neighbor_pos)
			if cost_grid[n_idx] >= COST_IMPASSABLE:
				continue
			
			var step_cost := cost_grid[n_idx]
			if i >= 4:
				var c_o1 := cost_grid[_index(Vector2i(neighbor_pos.x, curr_pos.y))]
				var c_o2 := cost_grid[_index(Vector2i(curr_pos.x, neighbor_pos.y))]
				if c_o1 >= COST_IMPASSABLE or c_o2 >= COST_IMPASSABLE:
					continue
				step_cost = maxf(step_cost, maxf(c_o1, c_o2))
			
			var cost: float = curr_cost + step_cost * NEIGHBOR_DIST[i]
			if integration_grid[n_idx] > cost:
				integration_grid[n_idx] = cost
				queue.push_back(n_idx)
	
	var end := Time.get_ticks_usec()
	print("Integration Time (usec): ", end - start)

## Update `field` based on the current values in `integration_grid` using an upwind (downhill-only) gradient
func _calculate_flow() -> void:
	var start := Time.get_ticks_usec()

	for grid_y in range(height):
		for grid_x in range(width):
			var curr_pos := Vector2i(grid_x, grid_y)
			var cell_idx := _index(curr_pos)
			var curr_cost: float = integration_grid[cell_idx]
			if curr_cost >= INTEGRATION_MAX or curr_cost == 0.0:
				field[cell_idx] = Vector2.ZERO
				continue

			var flow_vec := Vector2.ZERO

			for i in range(8):
				var neighbor_pos := curr_pos + NEIGHBORS[i]
				if not _is_in_bounds(neighbor_pos):
					continue
				
				var n_idx := _index(neighbor_pos)
				if cost_grid[n_idx] >= COST_IMPASSABLE:
					continue

				var step_cost := cost_grid[n_idx]
				if i >= 4:
					var c_o1 := cost_grid[_index(Vector2i(neighbor_pos.x, curr_pos.y))]
					var c_o2 := cost_grid[_index(Vector2i(curr_pos.x, neighbor_pos.y))]
					if c_o1 >= COST_IMPASSABLE or c_o2 >= COST_IMPASSABLE:
						continue
					step_cost = maxf(step_cost, maxf(c_o1, c_o2))

				var n_cost: float = integration_grid[n_idx]
				# Only consider neighbor if stepping into it is a valid path locally (not through a high-cost pinch)
				var transition_cost: float = n_cost + step_cost * NEIGHBOR_DIST[i]
				if transition_cost <= curr_cost + 0.5 and n_cost < curr_cost:
					var drop: float = (curr_cost - n_cost) / NEIGHBOR_DIST[i]
					flow_vec += NEIGHBOR_DIRS[i] * drop

			if flow_vec.length_squared() > 0.0001:
				field[cell_idx] = flow_vec.normalized()
			else:
				field[cell_idx] = Vector2.ZERO

	var end := Time.get_ticks_usec()
	print("Flow Time (usec): ", end - start)
