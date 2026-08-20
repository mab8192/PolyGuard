class_name FlowField extends RefCounted

## High-Performance Flow Field (Vector Field) Pathfinding with Macro Dynamic Congestion.
## Computes continuous finite-difference gradient vectors (-∇D) with Dijkstra wave-front
## that factors in dynamic enemy swarm congestion to route crowds around chokepoints.

const BLOCKED_COST: float = 100000.0
const TOWER_COST: float = 500.0
const SQRT_2: float = 1.41421356

var world_origin: Vector2 = Vector2.ZERO
var cell_size: Vector2 = Vector2(16.0, 16.0)
var grid_size: Vector2i = Vector2i.ZERO
var total_cells: int = 0
var bounds: Rect2:
	get: return Rect2(world_origin, Vector2(grid_size) * cell_size)

var base_cost: PackedFloat32Array = PackedFloat32Array()
var clearance_cost: PackedFloat32Array = PackedFloat32Array()
var congestion_cost: PackedFloat32Array = PackedFloat32Array()
var integration_cost: PackedFloat32Array = PackedFloat32Array()
var flow_vectors: PackedVector2Array = PackedVector2Array()

var cached_target_positions: Array[Vector2] = []

class FlatMinHeap:
	var costs: PackedFloat32Array = PackedFloat32Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var size: int = 0
	var top_cost: float = 0.0
	var top_index: int = 0

	func reset(capacity: int) -> void:
		if costs.size() < capacity:
			costs.resize(capacity)
			indices.resize(capacity)
		size = 0

	func push(cost: float, idx: int) -> void:
		if size >= costs.size():
			var new_cap = maxi(costs.size() * 2, 1024)
			costs.resize(new_cap)
			indices.resize(new_cap)
		
		var i = size
		size += 1
		# Sift up
		while i > 0:
			var parent = (i - 1) >> 1
			if cost < costs[parent]:
				costs[i] = costs[parent]
				indices[i] = indices[parent]
				i = parent
			else:
				break
		costs[i] = cost
		indices[i] = idx

	func pop() -> bool:
		if size == 0:
			return false
		top_cost = costs[0]
		top_index = indices[0]
		size -= 1
		if size > 0:
			var last_cost = costs[size]
			var last_idx = indices[size]
			var i = 0
			var half = size >> 1
			while i < half:
				var left = (i << 1) + 1
				var right = left + 1
				var best = left
				var best_cost = costs[left]
				if right < size and costs[right] < best_cost:
					best = right
					best_cost = costs[right]
				if best_cost < last_cost:
					costs[i] = best_cost
					indices[i] = indices[best]
					i = best
				else:
					break
			costs[i] = last_cost
			indices[i] = last_idx
		return true

	func is_empty() -> bool:
		return size == 0

var _heap: FlatMinHeap = FlatMinHeap.new()

func init_grid(bounds: Rect2, p_cell_size: Vector2 = Vector2(16.0, 16.0)) -> void:
	cell_size = p_cell_size
	world_origin = bounds.position
	grid_size = Vector2i(
		maxi(1, int(ceil(bounds.size.x / cell_size.x))),
		maxi(1, int(ceil(bounds.size.y / cell_size.y)))
	)
	total_cells = grid_size.x * grid_size.y

	base_cost.resize(total_cells)
	base_cost.fill(1.0)

	clearance_cost.resize(total_cells)
	clearance_cost.fill(0.0)

	congestion_cost.resize(total_cells)
	congestion_cost.fill(0.0)

	integration_cost.resize(total_cells)
	integration_cost.fill(BLOCKED_COST)

	flow_vectors.resize(total_cells)
	flow_vectors.fill(Vector2.ZERO)

	_heap.reset(total_cells * 2)

## Computes a clearance cost penalty on cells directly adjacent to walls
func update_wall_clearance() -> void:
	if clearance_cost.size() != total_cells:
		clearance_cost.resize(total_cells)
	clearance_cost.fill(0.0)

	var w: int = grid_size.x
	var h: int = grid_size.y

	const OFFSETS_ORTHO: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	const OFFSETS_DIAG: Array[Vector2i] = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]

	for gy: int in range(h):
		var row_offset: int = gy * w
		for gx: int in range(w):
			var idx: int = row_offset + gx
			if base_cost[idx] >= BLOCKED_COST:
				# Orthogonal neighbors get +1.5 clearance penalty
				for off: Vector2i in OFFSETS_ORTHO:
					var nx: int = gx + off.x
					var ny: int = gy + off.y
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						var n_idx: int = ny * w + nx
						if base_cost[n_idx] < BLOCKED_COST:
							clearance_cost[n_idx] = maxf(clearance_cost[n_idx], 1.5)

				# Diagonal neighbors get +0.8 clearance penalty
				for off: Vector2i in OFFSETS_DIAG:
					var nx: int = gx + off.x
					var ny: int = gy + off.y
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						var n_idx: int = ny * w + nx
						if base_cost[n_idx] < BLOCKED_COST:
							clearance_cost[n_idx] = maxf(clearance_cost[n_idx], 0.8)

## Fast local clearance update around a single placed tower rectangle (O(1))
func add_rect_clearance(rect: Rect2, penalty_ortho: float = 1.5, penalty_diag: float = 0.8) -> void:
	var min_cell: Vector2i = global_to_grid(rect.position)
	var max_cell: Vector2i = global_to_grid(rect.end - Vector2(0.001, 0.001))
	var w: int = grid_size.x
	var h: int = grid_size.y

	const OFFSETS_ORTHO: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	const OFFSETS_DIAG: Array[Vector2i] = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]

	for gy: int in range(min_cell.y, max_cell.y + 1):
		if gy < 0 or gy >= h:
			continue
		for gx: int in range(min_cell.x, max_cell.x + 1):
			if gx < 0 or gx >= w:
				continue
			var idx: int = gy * w + gx
			if base_cost[idx] >= TOWER_COST:
				for off: Vector2i in OFFSETS_ORTHO:
					var nx: int = gx + off.x
					var ny: int = gy + off.y
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						var n_idx: int = ny * w + nx
						if base_cost[n_idx] < TOWER_COST:
							clearance_cost[n_idx] = maxf(clearance_cost[n_idx], penalty_ortho)
				for off: Vector2i in OFFSETS_DIAG:
					var nx: int = gx + off.x
					var ny: int = gy + off.y
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						var n_idx: int = ny * w + nx
						if base_cost[n_idx] < TOWER_COST:
							clearance_cost[n_idx] = maxf(clearance_cost[n_idx], penalty_diag)

func clear_congestion() -> void:
	congestion_cost.fill(0.0)

func add_congestion(world_pos: Vector2, weight: float, radius: float = 32.0) -> void:
	if weight <= 0.0 or total_cells == 0:
		return
	var local: Vector2 = world_pos - world_origin
	var cx: int = int(floor(local.x / cell_size.x))
	var cy: int = int(floor(local.y / cell_size.y))
	var cell_radius: int = int(ceil(radius / cell_size.x))

	for dy: int in range(-cell_radius, cell_radius + 1):
		var gy: int = cy + dy
		if gy < 0 or gy >= grid_size.y:
			continue
		var row_offset: int = gy * grid_size.x
		for dx: int in range(-cell_radius, cell_radius + 1):
			var gx: int = cx + dx
			if gx < 0 or gx >= grid_size.x:
				continue
			var idx: int = row_offset + gx
			if base_cost[idx] < BLOCKED_COST:
				var cell_world: Vector2 = world_origin + (Vector2(gx, gy) + Vector2(0.5, 0.5)) * cell_size
				var dist: float = world_pos.distance_to(cell_world)
				if dist <= radius:
					var falloff: float = 1.0 - (dist / radius)
					congestion_cost[idx] += weight * falloff

func set_cell_blocked(gx: int, gy: int, blocked: bool) -> void:
	if is_valid_cell(gx, gy):
		var idx: int = gy * grid_size.x + gx
		base_cost[idx] = BLOCKED_COST if blocked else 1.0

func set_cell_cost(gx: int, gy: int, cost: float) -> void:
	if is_valid_cell(gx, gy):
		base_cost[gy * grid_size.x + gx] = cost

func set_rect_cost(rect: Rect2, cost: float, min_overlap_ratio: float = 0.0) -> void:
	var min_cell: Vector2i = global_to_grid(rect.position)
	var max_cell: Vector2i = global_to_grid(rect.end - Vector2(0.001, 0.001))
	var cell_area: float = cell_size.x * cell_size.y

	for gy: int in range(min_cell.y, max_cell.y + 1):
		if gy < 0 or gy >= grid_size.y:
			continue
		var cell_y0: float = world_origin.y + float(gy) * cell_size.y
		var cell_y1: float = cell_y0 + cell_size.y
		var overlap_y0: float = maxf(rect.position.y, cell_y0)
		var overlap_y1: float = minf(rect.end.y, cell_y1)
		var overlap_h: float = maxf(0.0, overlap_y1 - overlap_y0)
		if overlap_h <= 0.0:
			continue

		var row_offset: int = gy * grid_size.x
		for gx: int in range(min_cell.x, max_cell.x + 1):
			if gx < 0 or gx >= grid_size.x:
				continue
			var cell_x0: float = world_origin.x + float(gx) * cell_size.x
			var cell_x1: float = cell_x0 + cell_size.x
			var overlap_x0: float = maxf(rect.position.x, cell_x0)
			var overlap_x1: float = minf(rect.end.x, cell_x1)
			var overlap_w: float = maxf(0.0, overlap_x1 - overlap_x0)

			if overlap_w > 0.0:
				if min_overlap_ratio > 0.0:
					var ratio: float = (overlap_w * overlap_h) / cell_area
					if ratio < min_overlap_ratio:
						continue
				# Don't overwrite permanent walls (BLOCKED_COST) with tower costs
				if base_cost[row_offset + gx] < BLOCKED_COST:
					base_cost[row_offset + gx] = cost

func set_rect_blocked(rect: Rect2, blocked: bool, min_overlap_ratio: float = 0.0) -> void:
	set_rect_cost(rect, BLOCKED_COST if blocked else 1.0, min_overlap_ratio)

func global_to_grid(pos: Vector2) -> Vector2i:
	var local = pos - world_origin
	return Vector2i(
		int(floor(local.x / cell_size.x)),
		int(floor(local.y / cell_size.y))
	)

func grid_to_global(grid_pos: Vector2i) -> Vector2:
	return world_origin + (Vector2(grid_pos) + Vector2(0.5, 0.5)) * cell_size

func grid_to_index(gx: int, gy: int) -> int:
	return gy * grid_size.x + gx

func index_to_grid(idx: int) -> Vector2i:
	return Vector2i(idx % grid_size.x, idx / grid_size.x)

func is_valid_cell(gx: int, gy: int) -> bool:
	return gx >= 0 and gx < grid_size.x and gy >= 0 and gy < grid_size.y

func is_open_path(world_pos: Vector2) -> bool:
	if total_cells == 0:
		return false
	var local: Vector2 = world_pos - world_origin
	var gx: int = int(floor(local.x / cell_size.x))
	var gy: int = int(floor(local.y / cell_size.y))
	if is_valid_cell(gx, gy):
		var idx: int = gy * grid_size.x + gx
		if integration_cost[idx] < TOWER_COST:
			return true

	# Check a 1-cell neighborhood around world_pos to prevent false negatives near boundaries
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = gx + dx
			var ny: int = gy + dy
			if is_valid_cell(nx, ny):
				if integration_cost[ny * grid_size.x + nx] < TOWER_COST:
					return true
	return false

func is_reachable(world_pos: Vector2) -> bool:
	if total_cells == 0:
		return false
	var local: Vector2 = world_pos - world_origin
	var gx: int = int(floor(local.x / cell_size.x))
	var gy: int = int(floor(local.y / cell_size.y))
	if is_valid_cell(gx, gy):
		var idx: int = gy * grid_size.x + gx
		if integration_cost[idx] < BLOCKED_COST:
			return true

	# Check a 1-cell neighborhood around world_pos to prevent false unreachability near boundary hitboxes
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = gx + dx
			var ny: int = gy + dy
			if is_valid_cell(nx, ny):
				if integration_cost[ny * grid_size.x + nx] < BLOCKED_COST:
					return true
	return false

## Calculates integration fields for unified and per-exit fields in ONE Dijkstra wavefront pass
func calculate_multi_integration_fields(target_positions: Array[Vector2], out_per_exit_fields: Array) -> void:
	var start := Time.get_ticks_usec()
	var exit_count: int = target_positions.size()
	cached_target_positions = target_positions
	integration_cost.fill(BLOCKED_COST)

	if exit_count == 0 or total_cells == 0:
		flow_vectors.fill(Vector2.ZERO)
		return

	if exit_count == 1:
		calculate_integration_field(target_positions)
		if not out_per_exit_fields.is_empty() and out_per_exit_fields[0] != null:
			out_per_exit_fields[0].integration_cost = integration_cost.duplicate()
			out_per_exit_fields[0].flow_vectors = flow_vectors.duplicate()
		return

	for e: int in range(exit_count):
		if e < out_per_exit_fields.size() and out_per_exit_fields[e] != null:
			out_per_exit_fields[e].integration_cost.fill(BLOCKED_COST)

	_heap.reset(total_cells * exit_count * 2)

	var w: int = grid_size.x
	var h: int = grid_size.y
	var cs_x: float = cell_size.x
	var cs_y: float = cell_size.y

	for e: int in range(exit_count):
		var target_pos: Vector2 = target_positions[e]
		var exit_field: RefCounted = out_per_exit_fields[e] if e < out_per_exit_fields.size() else null
		var local: Vector2 = target_pos - world_origin
		var cx: int = int(floor(local.x / cs_x))
		var cy: int = int(floor(local.y / cs_y))

		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var gx: int = cx + dx
				var gy: int = cy + dy
				if gx >= 0 and gx < w and gy >= 0 and gy < h:
					var idx: int = gy * w + gx
					if base_cost[idx] < BLOCKED_COST:
						var cell_center: Vector2 = world_origin + Vector2((float(gx) + 0.5) * cs_x, (float(gy) + 0.5) * cs_y)
						var initial_dist: float = target_pos.distance_to(cell_center) / cs_x
						if exit_field != null and initial_dist < exit_field.integration_cost[idx]:
							exit_field.integration_cost[idx] = initial_dist
						if initial_dist < integration_cost[idx]:
							integration_cost[idx] = initial_dist
						_heap.push(initial_dist, (e << 18) | idx)

	# Precomputed 1D neighbor offsets: 0..3 ortho (E, W, S, N), 4..7 diag (SE, SW, NE, NW)
	var d_mult: Array[float] = [1.0, 1.0, 1.0, 1.0, SQRT_2, SQRT_2, SQRT_2, SQRT_2]

	while _heap.pop():
		var pop_cost: float = _heap.top_cost
		var item_id: int = _heap.top_index
		var exit_idx: int = item_id >> 18
		var curr_idx: int = item_id & 0x3FFFF

		var exit_field: RefCounted = out_per_exit_fields[exit_idx] if exit_idx < out_per_exit_fields.size() else null
		if exit_field != null and pop_cost > exit_field.integration_cost[curr_idx]:
			continue

		var gx: int = curr_idx % w
		var gy: int = curr_idx / w

		# 1. Orthogonal neighbors
		if gx < w - 1: # East (+1)
			_relax_multi_neighbor(curr_idx + 1, pop_cost, d_mult[0], exit_field, exit_idx)
		if gx > 0: # West (-1)
			_relax_multi_neighbor(curr_idx - 1, pop_cost, d_mult[1], exit_field, exit_idx)
		if gy < h - 1: # South (+w)
			_relax_multi_neighbor(curr_idx + w, pop_cost, d_mult[2], exit_field, exit_idx)
		if gy > 0: # North (-w)
			_relax_multi_neighbor(curr_idx - w, pop_cost, d_mult[3], exit_field, exit_idx)

		# 2. Diagonal neighbors (with corner-cutting protection)
		if gx < w - 1 and gy < h - 1: # SE (+w+1)
			if base_cost[curr_idx + 1] < TOWER_COST and base_cost[curr_idx + w] < TOWER_COST:
				_relax_multi_neighbor(curr_idx + w + 1, pop_cost, d_mult[4], exit_field, exit_idx)
		if gx > 0 and gy < h - 1: # SW (+w-1)
			if base_cost[curr_idx - 1] < TOWER_COST and base_cost[curr_idx + w] < TOWER_COST:
				_relax_multi_neighbor(curr_idx + w - 1, pop_cost, d_mult[5], exit_field, exit_idx)
		if gx < w - 1 and gy > 0: # NE (-w+1)
			if base_cost[curr_idx + 1] < TOWER_COST and base_cost[curr_idx - w] < TOWER_COST:
				_relax_multi_neighbor(curr_idx - w + 1, pop_cost, d_mult[6], exit_field, exit_idx)
		if gx > 0 and gy > 0: # NW (-w-1)
			if base_cost[curr_idx - 1] < TOWER_COST and base_cost[curr_idx - w] < TOWER_COST:
				_relax_multi_neighbor(curr_idx - w - 1, pop_cost, d_mult[7], exit_field, exit_idx)

	# Calculate continuous gradient vectors for unified field
	_calculate_continuous_gradient_vectors()

	# Precompute smooth continuous gradient vectors for each per-exit field
	for exit_field: RefCounted in out_per_exit_fields:
		if exit_field != null and exit_field.has_method("_calculate_continuous_gradient_vectors"):
			exit_field._calculate_continuous_gradient_vectors()

	var end = Time.get_ticks_usec()
	print("usec = ", end - start)

func _relax_multi_neighbor(n_idx: int, pop_cost: float, mult: float, exit_field: RefCounted, exit_idx: int) -> void:
	var n_base: float = base_cost[n_idx]
	if n_base >= BLOCKED_COST:
		return

	var cell_cost: float = n_base + clearance_cost[n_idx] + congestion_cost[n_idx]
	var tentative_dist: float = pop_cost + cell_cost * mult

	if exit_field != null and tentative_dist < exit_field.integration_cost[n_idx]:
		exit_field.integration_cost[n_idx] = tentative_dist
		if tentative_dist < integration_cost[n_idx]:
			integration_cost[n_idx] = tentative_dist
		_heap.push(tentative_dist, (exit_idx << 18) | n_idx)

## Calculates integration field (Dijkstra) including base costs + dynamic swarm congestion
func calculate_integration_field(target_positions: Array[Vector2]) -> void:
	cached_target_positions = target_positions
	integration_cost.fill(BLOCKED_COST)

	if target_positions.is_empty() or total_cells == 0:
		flow_vectors.fill(Vector2.ZERO)
		return

	_heap.reset(total_cells * 2)

	var w: int = grid_size.x
	var h: int = grid_size.y
	var cs_x: float = cell_size.x
	var cs_y: float = cell_size.y

	for target_pos: Vector2 in target_positions:
		var local: Vector2 = target_pos - world_origin
		var cx: int = int(floor(local.x / cs_x))
		var cy: int = int(floor(local.y / cs_y))

		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var gx: int = cx + dx
				var gy: int = cy + dy
				if gx >= 0 and gx < w and gy >= 0 and gy < h:
					var idx: int = gy * w + gx
					if base_cost[idx] < BLOCKED_COST:
						var cell_center: Vector2 = world_origin + Vector2((float(gx) + 0.5) * cs_x, (float(gy) + 0.5) * cs_y)
						var initial_dist: float = target_pos.distance_to(cell_center) / cs_x
						if initial_dist < integration_cost[idx]:
							integration_cost[idx] = initial_dist
							_heap.push(initial_dist, idx)

	var d_mult: Array[float] = [1.0, 1.0, 1.0, 1.0, SQRT_2, SQRT_2, SQRT_2, SQRT_2]

	while _heap.pop():
		var pop_cost: float = _heap.top_cost
		var curr_idx: int = _heap.top_index

		if pop_cost > integration_cost[curr_idx]:
			continue

		var gx: int = curr_idx % w
		var gy: int = curr_idx / w

		# 1. Orthogonal neighbors
		if gx < w - 1:
			_relax_single_neighbor(curr_idx + 1, pop_cost, d_mult[0])
		if gx > 0:
			_relax_single_neighbor(curr_idx - 1, pop_cost, d_mult[1])
		if gy < h - 1:
			_relax_single_neighbor(curr_idx + w, pop_cost, d_mult[2])
		if gy > 0:
			_relax_single_neighbor(curr_idx - w, pop_cost, d_mult[3])

		# 2. Diagonal neighbors (with corner-cutting protection)
		if gx < w - 1 and gy < h - 1:
			if base_cost[curr_idx + 1] < TOWER_COST and base_cost[curr_idx + w] < TOWER_COST:
				_relax_single_neighbor(curr_idx + w + 1, pop_cost, d_mult[4])
		if gx > 0 and gy < h - 1:
			if base_cost[curr_idx - 1] < TOWER_COST and base_cost[curr_idx + w] < TOWER_COST:
				_relax_single_neighbor(curr_idx + w - 1, pop_cost, d_mult[5])
		if gx < w - 1 and gy > 0:
			if base_cost[curr_idx + 1] < TOWER_COST and base_cost[curr_idx - w] < TOWER_COST:
				_relax_single_neighbor(curr_idx - w + 1, pop_cost, d_mult[6])
		if gx > 0 and gy > 0:
			if base_cost[curr_idx - 1] < TOWER_COST and base_cost[curr_idx - w] < TOWER_COST:
				_relax_single_neighbor(curr_idx - w - 1, pop_cost, d_mult[7])

	_calculate_continuous_gradient_vectors()

func _relax_single_neighbor(n_idx: int, pop_cost: float, mult: float) -> void:
	var n_base: float = base_cost[n_idx]
	if n_base >= BLOCKED_COST:
		return

	var cell_cost: float = n_base + clearance_cost[n_idx] + congestion_cost[n_idx]
	var tentative_dist: float = pop_cost + cell_cost * mult

	if tentative_dist < integration_cost[n_idx]:
		integration_cost[n_idx] = tentative_dist
		_heap.push(tentative_dist, n_idx)

## Fast continuous finite-difference gradient (-∇D) with lowest-neighbor fallback
func _calculate_continuous_gradient_vectors() -> void:
	var w: int = grid_size.x
	var h: int = grid_size.y

	if flow_vectors.size() != total_cells:
		flow_vectors.resize(total_cells)

	# 1. Fast interior cells (95% of grid, zero boundary branching)
	for gy: int in range(1, h - 1):
		var row_offset: int = gy * w
		for gx: int in range(1, w - 1):
			var idx: int = row_offset + gx
			var curr_cost: float = integration_cost[idx]

			if curr_cost >= BLOCKED_COST or curr_cost <= 0.0:
				flow_vectors[idx] = Vector2.ZERO
				continue

			var is_open: bool = curr_cost < TOWER_COST
			var max_valid_cost: float = TOWER_COST if is_open else BLOCKED_COST

			var c_l: float = integration_cost[idx - 1]
			var c_r: float = integration_cost[idx + 1]
			var c_u: float = integration_cost[idx - w]
			var c_d: float = integration_cost[idx + w]

			var b_l: bool = base_cost[idx - 1] < max_valid_cost and c_l < max_valid_cost
			var b_r: bool = base_cost[idx + 1] < max_valid_cost and c_r < max_valid_cost
			var b_u: bool = base_cost[idx - w] < max_valid_cost and c_u < max_valid_cost
			var b_d: bool = base_cost[idx + w] < max_valid_cost and c_d < max_valid_cost

			var grad_x: float = 0.0
			var grad_y: float = 0.0

			if b_l and b_r:
				grad_x = c_l - c_r
			elif b_l and c_l < curr_cost:
				grad_x = c_l - curr_cost
			elif b_r and c_r < curr_cost:
				grad_x = curr_cost - c_r

			if b_u and b_d:
				grad_y = c_u - c_d
			elif b_u and c_u < curr_cost:
				grad_y = c_u - curr_cost
			elif b_d and c_d < curr_cost:
				grad_y = curr_cost - c_d

			var grad_len_sq: float = grad_x * grad_x + grad_y * grad_y
			if grad_len_sq > 0.000001:
				var inv_l: float = 1.0 / sqrt(grad_len_sq)
				flow_vectors[idx] = Vector2(grad_x * inv_l, grad_y * inv_l)
				continue

			# 8-neighbor lowest cost fallback
			var lowest_cost: float = curr_cost
			var best_dx: float = 0.0
			var best_dy: float = 0.0

			if b_r and c_r < lowest_cost: lowest_cost = c_r; best_dx = 1.0; best_dy = 0.0
			if b_l and c_l < lowest_cost: lowest_cost = c_l; best_dx = -1.0; best_dy = 0.0
			if b_d and c_d < lowest_cost: lowest_cost = c_d; best_dx = 0.0; best_dy = 1.0
			if b_u and c_u < lowest_cost: lowest_cost = c_u; best_dx = 0.0; best_dy = -1.0

			var c_dr: float = integration_cost[idx + w + 1]
			if c_dr < lowest_cost and base_cost[idx + w + 1] < max_valid_cost and base_cost[idx + 1] < TOWER_COST and base_cost[idx + w] < TOWER_COST:
				lowest_cost = c_dr; best_dx = 1.0; best_dy = 1.0
			var c_dl: float = integration_cost[idx + w - 1]
			if c_dl < lowest_cost and base_cost[idx + w - 1] < max_valid_cost and base_cost[idx - 1] < TOWER_COST and base_cost[idx + w] < TOWER_COST:
				lowest_cost = c_dl; best_dx = -1.0; best_dy = 1.0
			var c_ur: float = integration_cost[idx - w + 1]
			if c_ur < lowest_cost and base_cost[idx - w + 1] < max_valid_cost and base_cost[idx + 1] < TOWER_COST and base_cost[idx - w] < TOWER_COST:
				lowest_cost = c_ur; best_dx = 1.0; best_dy = -1.0
			var c_ul: float = integration_cost[idx - w - 1]
			if c_ul < lowest_cost and base_cost[idx - w - 1] < max_valid_cost and base_cost[idx - 1] < TOWER_COST and base_cost[idx - w] < TOWER_COST:
				lowest_cost = c_ul; best_dx = -1.0; best_dy = -1.0

			if best_dx != 0.0 or best_dy != 0.0:
				var inv_len: float = 1.0 / sqrt(best_dx * best_dx + best_dy * best_dy)
				flow_vectors[idx] = Vector2(best_dx * inv_len, best_dy * inv_len)
			else:
				flow_vectors[idx] = Vector2.ZERO

	# 2. Boundary cells
	for gx: int in range(w):
		_calc_cell_gradient(gx, 0)
		_calc_cell_gradient(gx, h - 1)
	for gy: int in range(1, h - 1):
		_calc_cell_gradient(0, gy)
		_calc_cell_gradient(w - 1, gy)

func _calc_cell_gradient(gx: int, gy: int) -> void:
	var w: int = grid_size.x
	var h: int = grid_size.y
	var idx: int = gy * w + gx
	var curr_cost: float = integration_cost[idx]

	if curr_cost >= BLOCKED_COST or curr_cost <= 0.0:
		flow_vectors[idx] = Vector2.ZERO
		return

	var is_open: bool = curr_cost < TOWER_COST
	var max_valid_cost: float = TOWER_COST if is_open else BLOCKED_COST

	var has_left: bool = gx > 0 and base_cost[idx - 1] < max_valid_cost and integration_cost[idx - 1] < max_valid_cost
	var has_right: bool = gx < w - 1 and base_cost[idx + 1] < max_valid_cost and integration_cost[idx + 1] < max_valid_cost
	var has_up: bool = gy > 0 and base_cost[idx - w] < max_valid_cost and integration_cost[idx - w] < max_valid_cost
	var has_down: bool = gy < h - 1 and base_cost[idx + w] < max_valid_cost and integration_cost[idx + w] < max_valid_cost

	var grad_x: float = 0.0
	var grad_y: float = 0.0

	if has_left and has_right:
		grad_x = integration_cost[idx - 1] - integration_cost[idx + 1]
	elif has_left and integration_cost[idx - 1] < curr_cost:
		grad_x = integration_cost[idx - 1] - curr_cost
	elif has_right and integration_cost[idx + 1] < curr_cost:
		grad_x = curr_cost - integration_cost[idx + 1]

	if has_up and has_down:
		grad_y = integration_cost[idx - w] - integration_cost[idx + w]
	elif has_up and integration_cost[idx - w] < curr_cost:
		grad_y = integration_cost[idx - w] - curr_cost
	elif has_down and integration_cost[idx + w] < curr_cost:
		grad_y = curr_cost - integration_cost[idx + w]

	var grad_len_sq: float = grad_x * grad_x + grad_y * grad_y
	if grad_len_sq > 0.000001:
		var inv_l: float = 1.0 / sqrt(grad_len_sq)
		flow_vectors[idx] = Vector2(grad_x * inv_l, grad_y * inv_l)
	else:
		flow_vectors[idx] = Vector2.ZERO

## Smooth Bilinear Vector Sampling with Non-Zero Neighbor Blending
func sample_direction(world_pos: Vector2) -> Vector2:
	if total_cells == 0:
		return Vector2.ZERO

	var w: int = grid_size.x
	var h: int = grid_size.y

	# If flow_vectors are not precomputed (e.g. per-exit fields), compute on the fly in O(1)
	if flow_vectors.is_empty():
		var local: Vector2 = (world_pos - world_origin) / cell_size
		var gx: int = clampi(int(floor(local.x)), 1, w - 2)
		var gy: int = clampi(int(floor(local.y)), 1, h - 2)
		var idx: int = gy * w + gx
		var curr_cost: float = integration_cost[idx]
		var is_open: bool = curr_cost < TOWER_COST
		var max_valid_cost: float = TOWER_COST if is_open else BLOCKED_COST

		var c_l: float = integration_cost[idx - 1]
		var c_r: float = integration_cost[idx + 1]
		var c_u: float = integration_cost[idx - w]
		var c_d: float = integration_cost[idx + w]

		var b_l: bool = base_cost[idx - 1] < max_valid_cost and c_l < max_valid_cost
		var b_r: bool = base_cost[idx + 1] < max_valid_cost and c_r < max_valid_cost
		var b_u: bool = base_cost[idx - w] < max_valid_cost and c_u < max_valid_cost
		var b_d: bool = base_cost[idx + w] < max_valid_cost and c_d < max_valid_cost

		var grad_x: float = 0.0
		var grad_y: float = 0.0

		if b_l and b_r: grad_x = c_l - c_r
		elif b_l and c_l < curr_cost: grad_x = c_l - curr_cost
		elif b_r and c_r < curr_cost: grad_x = curr_cost - c_r

		if b_u and b_d: grad_y = c_u - c_d
		elif b_u and c_u < curr_cost: grad_y = c_u - curr_cost
		elif b_d and c_d < curr_cost: grad_y = curr_cost - c_d

		var l2: float = grad_x * grad_x + grad_y * grad_y
		if l2 > 0.0001:
			return Vector2(grad_x / sqrt(l2), grad_y / sqrt(l2))
		return Vector2.ZERO

	var local: Vector2 = (world_pos - world_origin - cell_size * 0.5) / cell_size
	var x0: int = int(floor(local.x))
	var y0: int = int(floor(local.y))
	var tx: float = clampf(local.x - float(x0), 0.0, 1.0)
	var ty: float = clampf(local.y - float(y0), 0.0, 1.0)

	var x1: int = x0 + 1
	var y1: int = y0 + 1

	var cx0: int = clampi(x0, 0, w - 1)
	var cx1: int = clampi(x1, 0, w - 1)
	var cy0: int = clampi(y0, 0, h - 1)
	var cy1: int = clampi(y1, 0, h - 1)

	var v00: Vector2 = flow_vectors[cy0 * w + cx0]
	var v10: Vector2 = flow_vectors[cy0 * w + cx1]
	var v01: Vector2 = flow_vectors[cy1 * w + cx0]
	var v11: Vector2 = flow_vectors[cy1 * w + cx1]

	var w00: float = (1.0 - tx) * (1.0 - ty)
	var w10: float = tx * (1.0 - ty)
	var w01: float = (1.0 - tx) * ty
	var w11: float = tx * ty

	var blended_dir: Vector2 = Vector2.ZERO
	var total_weight: float = 0.0

	if v00.length_squared() > 0.0001:
		blended_dir += v00 * w00
		total_weight += w00
	if v10.length_squared() > 0.0001:
		blended_dir += v10 * w10
		total_weight += w10
	if v01.length_squared() > 0.0001:
		blended_dir += v01 * w01
		total_weight += w01
	if v11.length_squared() > 0.0001:
		blended_dir += v11 * w11
		total_weight += w11

	if total_weight > 0.0001 and blended_dir.length_squared() > 0.0001:
		return (blended_dir / total_weight).normalized()

	# Fallback to nearest valid cell vector
	var gx: int = clampi(int(floor((world_pos.x - world_origin.x) / cell_size.x)), 0, w - 1)
	var gy: int = clampi(int(floor((world_pos.y - world_origin.y) / cell_size.y)), 0, h - 1)
	var base_dir: Vector2 = flow_vectors[gy * w + gx]
	if base_dir.length_squared() > 0.0001:
		return base_dir.normalized()

	return Vector2.ZERO

## Traces a continuous path streamline from start_pos to the closest exit using RK2 integration.
func trace_path(start_pos: Vector2, step_size: float = 8.0, max_steps: int = 400, exit_nodes: Array[Node2D] = []) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array([start_pos])
	var curr_pos: Vector2 = start_pos
	const EXIT_REACH_RADIUS_SQ: float = 54.0 * 54.0 ## Covers 64x64 exit area

	var last_grid: Vector2i = Vector2i(-999, -999)
	var same_cell_steps: int = 0

	for _step: int in range(max_steps):
		for exit: Node2D in exit_nodes:
			if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= EXIT_REACH_RADIUS_SQ:
				pts.append(exit.global_position)
				return pts

		var k1: Vector2 = sample_direction(curr_pos)
		if k1 == Vector2.ZERO:
			# If flow vector reached terminal zero near an exit, connect directly to closest exit
			for exit: Node2D in exit_nodes:
				if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= 80.0 * 80.0:
					pts.append(exit.global_position)
					return pts
			break

		# 2nd-order Runge-Kutta (RK2 midpoint) integration for smooth curvature
		var mid_pos: Vector2 = curr_pos + k1 * (step_size * 0.5)
		var k2: Vector2 = sample_direction(mid_pos)
		var step_dir: Vector2 = k2 if k2 != Vector2.ZERO else k1

		var next_pos: Vector2 = curr_pos + step_dir * step_size

		# If stepping into a permanent wall, slide along valid direction
		var g: Vector2i = global_to_grid(next_pos)
		if is_valid_cell(g.x, g.y):
			if base_cost[grid_to_index(g.x, g.y)] >= BLOCKED_COST:
				var slide_dir: Vector2 = sample_direction(curr_pos)
				if slide_dir != Vector2.ZERO:
					next_pos = curr_pos + slide_dir * (step_size * 0.5)
					var g_slide: Vector2i = global_to_grid(next_pos)
					if is_valid_cell(g_slide.x, g_slide.y) and base_cost[grid_to_index(g_slide.x, g_slide.y)] >= BLOCKED_COST:
						break
				else:
					break
		else:
			break

		if g == last_grid:
			same_cell_steps += 1
			if same_cell_steps > 8: # Stuck or oscillating in place
				break
		else:
			same_cell_steps = 0
			last_grid = g

		curr_pos = next_pos
		pts.append(curr_pos)

	# End of steps fallback: if ended close to an exit, connect to it
	for exit: Node2D in exit_nodes:
		if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= EXIT_REACH_RADIUS_SQ:
			pts.append(exit.global_position)
			break

	return pts
