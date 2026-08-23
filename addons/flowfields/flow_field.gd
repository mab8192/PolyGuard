class_name FlowField
extends RefCounted

## ============================================================================
## FlowField
## ----------------------------------------------------------------------------
## A high-performance, fully statically-typed flow field pathfinding grid for
## Godot 4, suitable for RTS/tower-defense unit movement where many agents share
## precomputed fields.
##
## Pipeline:
##   1. cost_field        - per-cell movement cost (1 = normal, 255 = wall)
##   2. integration_field - Dijkstra "distance to nearest goal" per cell
##   3. flow_field        - per-cell best direction (as a compact byte index)
##   4. flow_field_smooth - continuous Sobel-gradient vectors for smooth movement
## ============================================================================

signal bake_finished

## -- Constants ---------------------------------------------------------------

const COST_DEFAULT: int = 1
const COST_IMPASSABLE: int = 255
const INTEGRATION_MAX: int = 2147483647 # sentinel for "unreached" (int32 max)

# Direction index 0 = "none" (goal cell / unreachable cell).
# Indices 1-8 are the 8 neighbor directions, N,NE,E,SE,S,SW,W,NW (clockwise).
const DIR_OFFSETS_X: PackedInt32Array = [0, 0, 1, 1, 1, 0, -1, -1, -1]
const DIR_OFFSETS_Y: PackedInt32Array = [0, -1, -1, 0, 1, 1, 1, 0, -1]

const DIR_STEP_COST: PackedInt32Array = [0, 10, 14, 10, 14, 10, 14, 10, 14]
const WALL_GRADIENT_PENALTY: int = 10

## -- Public state --------------------------------------------------------------

var width: int
var height: int
var cell_size: float
var world_origin: Vector2

var cost_field: PackedByteArray
var integration_field: PackedInt32Array
var flow_field: PackedByteArray
var flow_field_smooth: PackedVector2Array

var smooth_gradient_flow: bool = true
var allow_diagonals: bool = true
var prevent_corner_cutting: bool = true

var _goal_indices: PackedInt32Array = PackedInt32Array()
var _dir_vectors: PackedVector2Array = PackedVector2Array()

var _bake_thread: Thread
var _baking: bool = false
var _heap: _FastMinHeap = _FastMinHeap.new()

## -- Construction --------------------------------------------------------------

func _init(p_width: int = 32, p_height: int = 32, p_cell_size: float = 32.0,
		p_origin: Vector2 = Vector2.ZERO) -> void:
	cell_size = p_cell_size
	world_origin = p_origin
	_build_dir_vectors()
	resize(p_width, p_height)


func _build_dir_vectors() -> void:
	_dir_vectors = PackedVector2Array()
	_dir_vectors.resize(9)
	_dir_vectors[0] = Vector2.ZERO
	for d: int in range(1, 9):
		var v: Vector2 = Vector2(float(DIR_OFFSETS_X[d]), float(DIR_OFFSETS_Y[d]))
		_dir_vectors[d] = v.normalized()


## Resizes the grid, resetting cost/integration/flow data and clearing goals.
func resize(new_width: int, new_height: int) -> void:
	width = maxi(1, new_width)
	height = maxi(1, new_height)
	var cell_count: int = width * height

	cost_field = PackedByteArray()
	cost_field.resize(cell_count)
	cost_field.fill(COST_DEFAULT)

	integration_field = PackedInt32Array()
	integration_field.resize(cell_count)
	integration_field.fill(INTEGRATION_MAX)

	flow_field = PackedByteArray()
	flow_field.resize(cell_count)

	flow_field_smooth = PackedVector2Array()
	flow_field_smooth.resize(cell_count)

	clear_goals()
	_heap.reset(cell_count * 2)


## -- Coordinate helpers ----------------------------------------------------

func is_valid_cell(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func grid_to_index(x: int, y: int) -> int:
	return y * width + x


func index_to_grid(index: int) -> Vector2i:
	return Vector2i(index % width, index / width)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = (world_pos - world_origin) / cell_size
	return Vector2i(int(floor(local.x)), int(floor(local.y)))


func grid_to_world(cell: Vector2i) -> Vector2:
	return world_origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


## -- Cost field editing ----------------------------------------------------

func get_cost(x: int, y: int) -> int:
	if not is_valid_cell(x, y):
		return COST_IMPASSABLE
	return cost_field[grid_to_index(x, y)]


func set_cost(x: int, y: int, cost: int) -> void:
	if not is_valid_cell(x, y):
		return
	cost_field[grid_to_index(x, y)] = clampi(cost, 1, 255)


func set_cost_world(world_pos: Vector2, cost: int) -> void:
	var cell: Vector2i = world_to_grid(world_pos)
	set_cost(cell.x, cell.y, cost)


func set_obstacle(x: int, y: int) -> void:
	set_cost(x, y, COST_IMPASSABLE)


func clear_obstacle(x: int, y: int) -> void:
	set_cost(x, y, COST_DEFAULT)


func set_cost_rect(rect: Rect2i, cost: int) -> void:
	var clamped_cost: int = clampi(cost, 1, 255)
	var x0: int = maxi(rect.position.x, 0)
	var y0: int = maxi(rect.position.y, 0)
	var x1: int = mini(rect.position.x + rect.size.x, width)
	var y1: int = mini(rect.position.y + rect.size.y, height)
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			cost_field[grid_to_index(x, y)] = clamped_cost


func set_obstacle_rect(rect: Rect2i) -> void:
	set_cost_rect(rect, COST_IMPASSABLE)


## Sets cost over a world space Rect2, with optional minimum overlap ratio test.
func set_rect_cost(rect: Rect2, cost: int, min_overlap_ratio: float = 0.0) -> void:
	var min_cell: Vector2i = world_to_grid(rect.position)
	var max_cell: Vector2i = world_to_grid(rect.end - Vector2(0.001, 0.001))
	var cell_area: float = cell_size * cell_size
	var clamped_cost: int = clampi(cost, 1, 255)

	for gy: int in range(min_cell.y, max_cell.y + 1):
		if gy < 0 or gy >= height:
			continue
		var cell_y0: float = world_origin.y + float(gy) * cell_size
		var cell_y1: float = cell_y0 + cell_size
		var overlap_y0: float = maxf(rect.position.y, cell_y0)
		var overlap_y1: float = minf(rect.end.y, cell_y1)
		var overlap_h: float = maxf(0.0, overlap_y1 - overlap_y0)
		if overlap_h <= 0.0:
			continue

		var row_offset: int = gy * width
		for gx: int in range(min_cell.x, max_cell.x + 1):
			if gx < 0 or gx >= width:
				continue
			var cell_x0: float = world_origin.x + float(gx) * cell_size
			var cell_x1: float = cell_x0 + cell_size
			var overlap_x0: float = maxf(rect.position.x, cell_x0)
			var overlap_x1: float = minf(rect.end.x, cell_x1)
			var overlap_w: float = maxf(0.0, overlap_x1 - overlap_x0)

			if overlap_w > 0.0:
				if min_overlap_ratio > 0.0:
					var ratio: float = (overlap_w * overlap_h) / cell_area
					if ratio < min_overlap_ratio:
						continue
				var idx: int = row_offset + gx
				if cost_field[idx] != COST_IMPASSABLE:
					cost_field[idx] = clamped_cost


func reset_costs() -> void:
	cost_field.fill(COST_DEFAULT)


## Builds the cost field from a TileMapLayer using collision or custom data layer.
func build_cost_from_tilemap(tilemap: TileMapLayer, custom_data_name: String = "solid") -> void:
	for y: int in range(height):
		for x: int in range(width):
			var cell: Vector2i = Vector2i(x, y)
			if tilemap.get_cell_source_id(cell) == -1:
				continue
			var tile_data: TileData = tilemap.get_cell_tile_data(cell)
			if tile_data == null:
				continue
			var blocked: bool = bool(tile_data.get_custom_data(custom_data_name)) or tile_data.get_collision_polygons_count(0) > 0
			cost_field[grid_to_index(x, y)] = COST_IMPASSABLE if blocked else COST_DEFAULT


## -- Goals -------------------------------------------------------------------

func clear_goals() -> void:
	_goal_indices = PackedInt32Array()


func add_goal_cell(cell: Vector2i) -> void:
	if not is_valid_cell(cell.x, cell.y):
		return
	_goal_indices.append(grid_to_index(cell.x, cell.y))


func add_goal_world(world_pos: Vector2) -> void:
	add_goal_cell(world_to_grid(world_pos))


func set_goal_cell(cell: Vector2i) -> void:
	clear_goals()
	add_goal_cell(cell)


func set_goal_world(world_pos: Vector2) -> void:
	clear_goals()
	add_goal_world(world_pos)


func set_goals_world(world_positions: Array[Vector2]) -> void:
	clear_goals()
	for pos: Vector2 in world_positions:
		add_goal_world(pos)


func has_goals() -> bool:
	return _goal_indices.size() > 0


## -- Baking ------------------------------------------------------------------

## Synchronous bake.
func bake() -> void:
	_compute_integration_field()
	_compute_flow_field()
	if smooth_gradient_flow:
		_compute_smooth_flow_field()
	bake_finished.emit()


## Asynchronous bake on a worker Thread.
func bake_async() -> void:
	if _baking:
		return
	_baking = true
	_bake_thread = Thread.new()
	_bake_thread.start(_bake_worker)


func is_baking() -> bool:
	return _baking


func _bake_worker() -> void:
	_compute_integration_field()
	_compute_flow_field()
	if smooth_gradient_flow:
		_compute_smooth_flow_field()
	call_deferred("_on_bake_thread_finished")


func _on_bake_thread_finished() -> void:
	if _bake_thread != null:
		_bake_thread.wait_to_finish()
		_bake_thread = null
	_baking = false
	bake_finished.emit()


func _compute_integration_field() -> void:
	var cell_count: int = width * height
	if integration_field.size() != cell_count:
		integration_field.resize(cell_count)
	integration_field.fill(INTEGRATION_MAX)

	_heap.reset(cell_count * 2)

	for goal_index: int in _goal_indices:
		if goal_index < 0 or goal_index >= cell_count:
			continue
		if cost_field[goal_index] == COST_IMPASSABLE:
			continue
		integration_field[goal_index] = 0
		_heap.push(0, goal_index)

	var dir_count: int = 9 if allow_diagonals else 5

	while not _heap.is_empty():
		var top: Vector2i = _heap.pop_min()
		var dist: int = top.x
		var idx: int = top.y

		if dist > integration_field[idx]:
			continue

		var cx: int = idx % width
		var cy: int = idx / width

		for d: int in range(1, dir_count):
			var nx: int = cx + DIR_OFFSETS_X[d]
			var ny: int = cy + DIR_OFFSETS_Y[d]
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue

			var n_idx: int = ny * width + nx
			var n_cost: int = cost_field[n_idx]
			if n_cost == COST_IMPASSABLE:
				continue

			# Diagonal directions are even indices (2, 4, 6, 8)
			if prevent_corner_cutting and (d % 2 == 0):
				var flank_a: int = cy * width + nx
				var flank_b: int = ny * width + cx
				if cost_field[flank_a] == COST_IMPASSABLE or cost_field[flank_b] == COST_IMPASSABLE:
					continue

			var new_dist: int = dist + DIR_STEP_COST[d] * n_cost
			if new_dist < integration_field[n_idx]:
				integration_field[n_idx] = new_dist
				_heap.push(new_dist, n_idx)


func _compute_flow_field() -> void:
	var cell_count: int = width * height
	if flow_field.size() != cell_count:
		flow_field.resize(cell_count)

	for idx: int in range(cell_count):
		var current_val: int = integration_field[idx]
		if cost_field[idx] == COST_IMPASSABLE or current_val == INTEGRATION_MAX or current_val == 0:
			flow_field[idx] = 0
			continue

		var cx: int = idx % width
		var cy: int = idx / width
		var best_dir: int = 0
		var best_val: int = current_val

		for d: int in range(1, 9):
			var nx: int = cx + DIR_OFFSETS_X[d]
			var ny: int = cy + DIR_OFFSETS_Y[d]
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue
			var n_val: int = integration_field[ny * width + nx]
			if n_val < best_val:
				best_val = n_val
				best_dir = d

		flow_field[idx] = best_dir


## Derives a continuous per-cell direction from the integration field using a
## Sobel-style 3x3 gradient estimate.
func _compute_smooth_flow_field() -> void:
	var cell_count: int = width * height
	if flow_field_smooth.size() != cell_count:
		flow_field_smooth.resize(cell_count)

	for idx: int in range(cell_count):
		var self_val: int = integration_field[idx]
		if cost_field[idx] == COST_IMPASSABLE or self_val == INTEGRATION_MAX or self_val == 0:
			flow_field_smooth[idx] = Vector2.ZERO
			continue

		var cx: int = idx % width
		var cy: int = idx / width

		var tl: int = _sample_integration_for_gradient(cx - 1, cy - 1, self_val)
		var tc: int = _sample_integration_for_gradient(cx, cy - 1, self_val)
		var tr: int = _sample_integration_for_gradient(cx + 1, cy - 1, self_val)
		var ml: int = _sample_integration_for_gradient(cx - 1, cy, self_val)
		var mr: int = _sample_integration_for_gradient(cx + 1, cy, self_val)
		var bl: int = _sample_integration_for_gradient(cx - 1, cy + 1, self_val)
		var bc: int = _sample_integration_for_gradient(cx, cy + 1, self_val)
		var br: int = _sample_integration_for_gradient(cx + 1, cy + 1, self_val)

		# Sobel X / Sobel Y kernels applied to the integration "height field".
		var gx: float = float((tr + 2 * mr + br) - (tl + 2 * ml + bl))
		var gy: float = float((bl + 2 * bc + br) - (tl + 2 * tc + tr))

		var grad: Vector2 = Vector2(gx, gy)
		var discrete_dir: Vector2 = _dir_vectors[flow_field[idx]]
		if grad.length_squared() < 0.0001:
			flow_field_smooth[idx] = discrete_dir
		else:
			var smooth_dir: Vector2 = - grad.normalized()
			# If the Sobel gradient deviates heavily from Dijkstra (e.g. in a narrow 1-tile pinch
			# where surrounding walls corrupt the gradient), fall back to the exact Dijkstra direction.
			if discrete_dir != Vector2.ZERO and smooth_dir.dot(discrete_dir) < 0.3:
				flow_field_smooth[idx] = discrete_dir
			else:
				flow_field_smooth[idx] = smooth_dir


func _sample_integration_for_gradient(x: int, y: int, self_value: int) -> int:
	if not is_valid_cell(x, y):
		return self_value + WALL_GRADIENT_PENALTY
	var idx: int = grid_to_index(x, y)
	if cost_field[idx] == COST_IMPASSABLE or integration_field[idx] == INTEGRATION_MAX:
		return self_value + WALL_GRADIENT_PENALTY
	if cost_field[idx] > COST_DEFAULT:
		return self_value + WALL_GRADIENT_PENALTY
	return integration_field[idx]


## -- Sampling (for agents) ---------------------------------------------------

func get_flow_vector(x: int, y: int) -> Vector2:
	if not is_valid_cell(x, y):
		return Vector2.ZERO
	var idx: int = grid_to_index(x, y)
	if smooth_gradient_flow and idx < flow_field_smooth.size():
		return flow_field_smooth[idx]
	return _dir_vectors[flow_field[idx]]


func get_all_flow_vectors() -> PackedVector2Array:
	if smooth_gradient_flow and flow_field_smooth.size() == flow_field.size():
		return flow_field_smooth.duplicate()
	var result: PackedVector2Array = PackedVector2Array()
	result.resize(flow_field.size())
	for i: int in range(flow_field.size()):
		result[i] = _dir_vectors[flow_field[i]]
	return result


func get_integration_at_world(world_pos: Vector2) -> int:
	var cell: Vector2i = world_to_grid(world_pos)
	if not is_valid_cell(cell.x, cell.y):
		return INTEGRATION_MAX
	return integration_field[grid_to_index(cell.x, cell.y)]


func has_reached_goal_world(world_pos: Vector2) -> bool:
	return get_integration_at_world(world_pos) == 0


func is_reachable(world_pos: Vector2) -> bool:
	return get_integration_at_world(world_pos) < INTEGRATION_MAX


func is_open_path(world_pos: Vector2, max_open_cost: int = 800) -> bool:
	var cost: int = get_integration_at_world(world_pos)
	return cost < max_open_cost


## Samples the flow direction at a world position using bilinear interpolation.
func sample_flow_world(world_pos: Vector2, smooth: bool = true) -> Vector2:
	if not smooth:
		var cell: Vector2i = world_to_grid(world_pos)
		return get_flow_vector(cell.x, cell.y)

	var local: Vector2 = (world_pos - world_origin - Vector2(cell_size * 0.5, cell_size * 0.5)) / cell_size
	var gx: int = int(floor(local.x))
	var gy: int = int(floor(local.y))

	var fx: float = clampf(local.x - float(gx), 0.0, 1.0)
	var fy: float = clampf(local.y - float(gy), 0.0, 1.0)

	var x0: int = clampi(gx, 0, width - 1)
	var x1: int = clampi(gx + 1, 0, width - 1)
	var y0: int = clampi(gy, 0, height - 1)
	var y1: int = clampi(gy + 1, 0, height - 1)

	var v00: Vector2 = get_flow_vector(x0, y0)
	var v10: Vector2 = get_flow_vector(x1, y0)
	var v01: Vector2 = get_flow_vector(x0, y1)
	var v11: Vector2 = get_flow_vector(x1, y1)

	var w00: float = (1.0 - fx) * (1.0 - fy)
	var w10: float = fx * (1.0 - fy)
	var w01: float = (1.0 - fx) * fy
	var w11: float = fx * fy

	var c00: int = cost_field[grid_to_index(x0, y0)]
	var c10: int = cost_field[grid_to_index(x1, y0)]
	var c01: int = cost_field[grid_to_index(x0, y1)]
	var c11: int = cost_field[grid_to_index(x1, y1)]

	var blended: Vector2 = Vector2.ZERO
	var weight_sum: float = 0.0

	if v00 != Vector2.ZERO and c00 <= COST_DEFAULT:
		blended += v00 * w00
		weight_sum += w00
	if v10 != Vector2.ZERO and c10 <= COST_DEFAULT:
		blended += v10 * w10
		weight_sum += w10
	if v01 != Vector2.ZERO and c01 <= COST_DEFAULT:
		blended += v01 * w01
		weight_sum += w01
	if v11 != Vector2.ZERO and c11 <= COST_DEFAULT:
		blended += v11 * w11
		weight_sum += w11

	if weight_sum > 0.001 and blended.length_squared() > 0.0001:
		return blended.normalized()

	var exact_cell: Vector2i = world_to_grid(world_pos)
	return get_flow_vector(exact_cell.x, exact_cell.y)


## Traces a continuous path streamline from start_pos to goal/exit using RK2 integration.
func trace_path(start_pos: Vector2, step_size: float = 8.0, max_steps: int = 400,
		exit_nodes: Array[Node2D] = []) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array([start_pos])
	var curr_pos: Vector2 = start_pos
	const EXIT_REACH_RADIUS_SQ: float = 48.0 * 48.0

	for _step: int in range(max_steps):
		for exit: Node2D in exit_nodes:
			if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= EXIT_REACH_RADIUS_SQ:
				pts.append(exit.global_position)
				return pts

		var k1: Vector2 = sample_flow_world(curr_pos, true)
		if k1 == Vector2.ZERO:
			for exit: Node2D in exit_nodes:
				if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= 80.0 * 80.0:
					pts.append(exit.global_position)
					return pts
			break

		# RK2 midpoint step
		var mid_pos: Vector2 = curr_pos + k1 * (step_size * 0.5)
		var k2: Vector2 = sample_flow_world(mid_pos, true)
		var dir: Vector2 = (k1 + k2).normalized() if (k1 + k2).length_squared() > 0.001 else k1

		var next_pos: Vector2 = curr_pos + dir * step_size
		var next_cell: Vector2i = world_to_grid(next_pos)

		# If the continuous step enters an obstacle cell (wall or tower), advance using the discrete Dijkstra direction
		if is_valid_cell(next_cell.x, next_cell.y) and cost_field[grid_to_index(next_cell.x, next_cell.y)] > COST_DEFAULT:
			var curr_cell: Vector2i = world_to_grid(curr_pos)
			if is_valid_cell(curr_cell.x, curr_cell.y) and cost_field[grid_to_index(curr_cell.x, curr_cell.y)] <= COST_DEFAULT:
				var discrete_step_dir: Vector2 = _dir_vectors[flow_field[grid_to_index(curr_cell.x, curr_cell.y)]]
				if discrete_step_dir != Vector2.ZERO:
					next_pos = curr_pos + discrete_step_dir * step_size
				else:
					break
			else:
				break

		if curr_pos.distance_squared_to(next_pos) < 0.25:
			break

		pts.append(next_pos)
		curr_pos = next_pos

	return pts


## -- Fast Pre-allocated MinHeap ----------------------------------------------
class _FastMinHeap:
	var _dist: PackedInt32Array = PackedInt32Array()
	var _idx: PackedInt32Array = PackedInt32Array()
	var _size: int = 0

	func reset(capacity: int) -> void:
		if _dist.size() < capacity:
			_dist.resize(capacity)
			_idx.resize(capacity)
		_size = 0

	func is_empty() -> bool:
		return _size == 0

	func push(dist: int, index: int) -> void:
		if _size >= _dist.size():
			var new_cap: int = maxi(_dist.size() * 2, 1024)
			_dist.resize(new_cap)
			_idx.resize(new_cap)

		var i: int = _size
		_size += 1

		while i > 0:
			var parent: int = (i - 1) >> 1
			if dist < _dist[parent]:
				_dist[i] = _dist[parent]
				_idx[i] = _idx[parent]
				i = parent
			else:
				break
		_dist[i] = dist
		_idx[i] = index

	func pop_min() -> Vector2i:
		if _size == 0:
			return Vector2i(INTEGRATION_MAX, -1)
		var top_dist: int = _dist[0]
		var top_idx: int = _idx[0]
		_size -= 1
		if _size > 0:
			var last_dist: int = _dist[_size]
			var last_idx: int = _idx[_size]
			var i: int = 0
			var half: int = _size >> 1
			while i < half:
				var left: int = (i << 1) + 1
				var right: int = left + 1
				var best: int = left
				var best_dist: int = _dist[left]
				if right < _size and _dist[right] < best_dist:
					best = right
					best_dist = _dist[right]
				if best_dist < last_dist:
					_dist[i] = best_dist
					_idx[i] = _idx[best]
					i = best
				else:
					break
			_dist[i] = last_dist
			_idx[i] = last_idx
		return Vector2i(top_dist, top_idx)
