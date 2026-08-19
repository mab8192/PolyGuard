class_name FlowField extends RefCounted

## High-Performance Flow Field (Vector Field) Pathfinding with Macro Dynamic Congestion.
## Computes continuous finite-difference gradient vectors (-∇D) with Dijkstra wave-front
## that factors in dynamic enemy swarm congestion to route crowds around chokepoints.

const BLOCKED_COST: float = 100000.0
const SQRT_2: float = 1.41421356

var world_origin: Vector2 = Vector2.ZERO
var cell_size: Vector2 = Vector2(32.0, 32.0)
var grid_size: Vector2i = Vector2i.ZERO
var total_cells: int = 0

var base_cost: PackedFloat32Array = PackedFloat32Array()
var congestion_cost: PackedFloat32Array = PackedFloat32Array()
var integration_cost: PackedFloat32Array = PackedFloat32Array()
var flow_vectors: PackedVector2Array = PackedVector2Array()

var cached_target_positions: Array[Vector2] = []

class FlatMinHeap:
	var costs: PackedFloat32Array = PackedFloat32Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var size: int = 0

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
		costs[size] = cost
		indices[size] = idx
		_up(size)
		size += 1

	func pop_index() -> int:
		if size == 0:
			return -1
		var top_idx = indices[0]
		size -= 1
		if size > 0:
			costs[0] = costs[size]
			indices[0] = indices[size]
			_down(0)
		return top_idx

	func is_empty() -> bool:
		return size == 0

	func _up(idx: int) -> void:
		var c = costs[idx]
		var item_idx = indices[idx]
		while idx > 0:
			var parent = (idx - 1) >> 1
			if c < costs[parent]:
				costs[idx] = costs[parent]
				indices[idx] = indices[parent]
				idx = parent
			else:
				break
		costs[idx] = c
		indices[idx] = item_idx

	func _down(idx: int) -> void:
		var c = costs[idx]
		var item_idx = indices[idx]
		while true:
			var smallest = idx
			var left = (idx << 1) + 1
			var right = left + 1
			if left < size and costs[left] < costs[smallest]:
				smallest = left
			if right < size and costs[right] < costs[smallest]:
				smallest = right
			if smallest != idx:
				costs[idx] = costs[smallest]
				indices[idx] = indices[smallest]
				idx = smallest
			else:
				break
		costs[idx] = c
		indices[idx] = item_idx

var _heap: FlatMinHeap = FlatMinHeap.new()

func init_grid(bounds: Rect2, p_cell_size: Vector2 = Vector2(32.0, 32.0)) -> void:
	cell_size = p_cell_size
	world_origin = bounds.position
	grid_size = Vector2i(
		maxi(1, int(ceil(bounds.size.x / cell_size.x))),
		maxi(1, int(ceil(bounds.size.y / cell_size.y)))
	)
	total_cells = grid_size.x * grid_size.y

	base_cost.resize(total_cells)
	base_cost.fill(1.0)

	congestion_cost.resize(total_cells)
	congestion_cost.fill(0.0)

	integration_cost.resize(total_cells)
	integration_cost.fill(BLOCKED_COST)

	flow_vectors.resize(total_cells)
	flow_vectors.fill(Vector2.ZERO)

	_heap.reset(total_cells * 2)

func clear_congestion() -> void:
	congestion_cost.fill(0.0)

func add_congestion(world_pos: Vector2, weight: float, radius: float = 32.0) -> void:
	if weight <= 0.0 or total_cells == 0:
		return
	var local = world_pos - world_origin
	var cx = int(floor(local.x / cell_size.x))
	var cy = int(floor(local.y / cell_size.y))
	var cell_radius = int(ceil(radius / cell_size.x))

	for dy in range(-cell_radius, cell_radius + 1):
		var gy = cy + dy
		if gy < 0 or gy >= grid_size.y:
			continue
		var row_offset = gy * grid_size.x
		for dx in range(-cell_radius, cell_radius + 1):
			var gx = cx + dx
			if gx < 0 or gx >= grid_size.x:
				continue
			var idx = row_offset + gx
			if base_cost[idx] < BLOCKED_COST:
				var cell_world = world_origin + (Vector2(gx, gy) + Vector2(0.5, 0.5)) * cell_size
				var dist = world_pos.distance_to(cell_world)
				if dist <= radius:
					var falloff = 1.0 - (dist / radius)
					congestion_cost[idx] += weight * falloff

func set_cell_blocked(gx: int, gy: int, blocked: bool) -> void:
	if is_valid_cell(gx, gy):
		var idx = gy * grid_size.x + gx
		base_cost[idx] = BLOCKED_COST if blocked else 1.0

func set_rect_blocked(rect: Rect2, blocked: bool) -> void:
	var min_cell = global_to_grid(rect.position)
	var max_cell = global_to_grid(rect.end - Vector2(0.1, 0.1))

	for gy in range(min_cell.y, max_cell.y + 1):
		for gx in range(min_cell.x, max_cell.x + 1):
			set_cell_blocked(gx, gy, blocked)

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

func is_reachable(world_pos: Vector2) -> bool:
	var local = world_pos - world_origin
	var gx = int(floor(local.x / cell_size.x))
	var gy = int(floor(local.y / cell_size.y))
	if gx < 0 or gx >= grid_size.x or gy < 0 or gy >= grid_size.y:
		return false
	var idx = gy * grid_size.x + gx
	if integration_cost[idx] < BLOCKED_COST:
		return true

	const OFFSETS = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for off in OFFSETS:
		var nx = gx + off.x
		var ny = gy + off.y
		if nx >= 0 and nx < grid_size.x and ny >= 0 and ny < grid_size.y:
			if integration_cost[ny * grid_size.x + nx] < BLOCKED_COST:
				return true
	return false

## Calculates integration field (Dijkstra) including base costs + dynamic swarm congestion
func calculate_integration_field(target_positions: Array[Vector2]) -> void:
	cached_target_positions = target_positions
	integration_cost.fill(BLOCKED_COST)

	if target_positions.is_empty() or total_cells == 0:
		flow_vectors.fill(Vector2.ZERO)
		return

	_heap.reset(total_cells * 2)

	var w = grid_size.x
	var h = grid_size.y

	for target_pos in target_positions:
		var local = target_pos - world_origin
		var cx = int(floor(local.x / cell_size.x))
		var cy = int(floor(local.y / cell_size.y))

		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var gx = cx + dx
				var gy = cy + dy
				if gx >= 0 and gx < w and gy >= 0 and gy < h:
					var idx = gy * w + gx
					if base_cost[idx] < BLOCKED_COST:
						var cell_center = world_origin + (Vector2(gx, gy) + Vector2(0.5, 0.5)) * cell_size
						var initial_dist = target_pos.distance_to(cell_center) / cell_size.x
						if initial_dist < integration_cost[idx]:
							integration_cost[idx] = initial_dist
							_heap.push(initial_dist, idx)

	const NEIGHBORS = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	const DIST_MULT = [1.0, 1.0, 1.0, 1.0, SQRT_2, SQRT_2, SQRT_2, SQRT_2]

	while not _heap.is_empty():
		var curr_idx: int = _heap.pop_index()
		if curr_idx < 0:
			break
		var curr_dist: float = integration_cost[curr_idx]
		if curr_dist >= BLOCKED_COST:
			continue

		var gx = curr_idx % w
		var gy = curr_idx / w

		for i in range(8):
			var nx = gx + NEIGHBORS[i].x
			var ny = gy + NEIGHBORS[i].y

			if nx < 0 or nx >= w or ny < 0 or ny >= h:
				continue

			var n_idx = ny * w + nx
			var n_base = base_cost[n_idx]
			if n_base >= BLOCKED_COST:
				continue

			# Diagonal corner-cutting safety check
			if i >= 4:
				if base_cost[gy * w + nx] >= BLOCKED_COST or base_cost[ny * w + gx] >= BLOCKED_COST:
					continue

			# Effective cell cost includes dynamic enemy congestion
			var cell_cost = n_base + congestion_cost[n_idx]
			var tentative_dist = curr_dist + cell_cost * DIST_MULT[i]

			if tentative_dist < integration_cost[n_idx]:
				integration_cost[n_idx] = tentative_dist
				_heap.push(tentative_dist, n_idx)

	_calculate_continuous_gradient_vectors()

## Emerson continuous finite-difference gradient (-∇D) with lowest-neighbor fallback
func _calculate_continuous_gradient_vectors() -> void:
	var w = grid_size.x
	var h = grid_size.y

	const NEIGHBORS_8 = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]

	for gy in range(h):
		var row_offset = gy * w
		for gx in range(w):
			var idx = row_offset + gx
			var curr_cost = integration_cost[idx]

			if curr_cost >= BLOCKED_COST or curr_cost <= 0.0:
				flow_vectors[idx] = Vector2.ZERO
				continue

			var has_left = gx > 0 and base_cost[idx - 1] < BLOCKED_COST and integration_cost[idx - 1] < BLOCKED_COST
			var has_right = gx < w - 1 and base_cost[idx + 1] < BLOCKED_COST and integration_cost[idx + 1] < BLOCKED_COST
			var has_up = gy > 0 and base_cost[idx - w] < BLOCKED_COST and integration_cost[idx - w] < BLOCKED_COST
			var has_down = gy < h - 1 and base_cost[idx + w] < BLOCKED_COST and integration_cost[idx + w] < BLOCKED_COST

			var grad_x: float = 0.0
			var grad_y: float = 0.0

			# X-axis gradient: points downhill (cost(left) - cost(right))
			if has_left and has_right:
				grad_x = integration_cost[idx - 1] - integration_cost[idx + 1]
			elif has_left and not has_right:
				if integration_cost[idx - 1] < curr_cost:
					grad_x = integration_cost[idx - 1] - curr_cost
				else:
					grad_x = 0.0
			elif has_right and not has_left:
				if integration_cost[idx + 1] < curr_cost:
					grad_x = curr_cost - integration_cost[idx + 1]
				else:
					grad_x = 0.0

			# Y-axis gradient: points downhill (cost(up) - cost(down))
			if has_up and has_down:
				grad_y = integration_cost[idx - w] - integration_cost[idx + w]
			elif has_up and not has_down:
				if integration_cost[idx - w] < curr_cost:
					grad_y = integration_cost[idx - w] - curr_cost
				else:
					grad_y = 0.0
			elif has_down and not has_up:
				if integration_cost[idx + w] < curr_cost:
					grad_y = curr_cost - integration_cost[idx + w]
				else:
					grad_y = 0.0

			if absf(grad_x) > 0.001 or absf(grad_y) > 0.001:
				var inv_l = 1.0 / sqrt(grad_x * grad_x + grad_y * grad_y)
				flow_vectors[idx] = Vector2(grad_x * inv_l, grad_y * inv_l)
				continue

			# 8-neighbor lowest cost fallback
			var lowest_cost: float = curr_cost
			var best_dx: float = 0.0
			var best_dy: float = 0.0

			for i in range(8):
				var nx = gx + NEIGHBORS_8[i].x
				var ny = gy + NEIGHBORS_8[i].y
				if nx < 0 or nx >= w or ny < 0 or ny >= h:
					continue

				var n_idx = ny * w + nx
				if base_cost[n_idx] >= BLOCKED_COST:
					continue

				if i >= 4:
					if base_cost[row_offset + nx] >= BLOCKED_COST or base_cost[ny * w + gx] >= BLOCKED_COST:
						continue

				var n_cost = integration_cost[n_idx]
				if n_cost < lowest_cost:
					lowest_cost = n_cost
					best_dx = float(NEIGHBORS_8[i].x)
					best_dy = float(NEIGHBORS_8[i].y)

			if best_dx != 0.0 or best_dy != 0.0:
				var inv_len = 1.0 / sqrt(best_dx * best_dx + best_dy * best_dy)
				flow_vectors[idx] = Vector2(best_dx * inv_len, best_dy * inv_len)
			else:
				flow_vectors[idx] = Vector2.ZERO

## Smooth Bilinear Vector Sampling
func sample_direction(world_pos: Vector2) -> Vector2:
	if total_cells == 0:
		return Vector2.ZERO

	var local = (world_pos - world_origin - cell_size * 0.5) / cell_size
	var x0 = int(floor(local.x))
	var y0 = int(floor(local.y))
	var tx = local.x - float(x0)
	var ty = local.y - float(y0)

	var x1 = x0 + 1
	var y1 = y0 + 1

	var w = grid_size.x
	var h = grid_size.y

	var cx0 = clampi(x0, 0, w - 1)
	var cx1 = clampi(x1, 0, w - 1)
	var cy0 = clampi(y0, 0, h - 1)
	var cy1 = clampi(y1, 0, h - 1)

	var v00 = flow_vectors[cy0 * w + cx0]
	var v10 = flow_vectors[cy0 * w + cx1]
	var v01 = flow_vectors[cy1 * w + cx0]
	var v11 = flow_vectors[cy1 * w + cx1]

	var base_dir: Vector2 = Vector2.ZERO
	if v00 != Vector2.ZERO and v10 != Vector2.ZERO and v01 != Vector2.ZERO and v11 != Vector2.ZERO:
		var top = lerp(v00, v10, tx)
		var bottom = lerp(v01, v11, tx)
		base_dir = lerp(top, bottom, ty)
	else:
		var gx = clampi(int(floor((world_pos.x - world_origin.x) / cell_size.x)), 0, w - 1)
		var gy = clampi(int(floor((world_pos.y - world_origin.y) / cell_size.y)), 0, h - 1)
		base_dir = flow_vectors[gy * w + gx]
		if base_dir == Vector2.ZERO:
			if v00 != Vector2.ZERO: base_dir = v00
			elif v10 != Vector2.ZERO: base_dir = v10
			elif v01 != Vector2.ZERO: base_dir = v01
			elif v11 != Vector2.ZERO: base_dir = v11

	if base_dir.length_squared() < 0.0001:
		return Vector2.ZERO

	return base_dir.normalized()

## Traces a continuous path streamline from start_pos to the closest exit.
func trace_path(start_pos: Vector2, step_size: float = 16.0, max_steps: int = 500, exit_nodes: Array[Node2D] = []) -> PackedVector2Array:
	var pts = PackedVector2Array([start_pos])
	var curr_pos = start_pos
	var exit_reach_radius_sq = (cell_size.x * 2.0) * (cell_size.x * 2.0)

	for _step in range(max_steps):
		for exit in exit_nodes:
			if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= exit_reach_radius_sq:
				pts.append(exit.global_position)
				return pts

		var dir = sample_direction(curr_pos)
		if dir == Vector2.ZERO:
			break

		var next_pos = curr_pos + dir * step_size

		# If stepping into a blocked cell, project to nearest open cell
		var g = global_to_grid(next_pos)
		if is_valid_cell(g.x, g.y) and base_cost[grid_to_index(g.x, g.y)] >= BLOCKED_COST:
			var open_found: bool = false
			const OFFSETS = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for off in OFFSETS:
				var test_g = global_to_grid(curr_pos) + off
				if is_valid_cell(test_g.x, test_g.y) and base_cost[grid_to_index(test_g.x, test_g.y)] < BLOCKED_COST:
					next_pos = grid_to_global(test_g)
					open_found = true
					break
			if not open_found:
				break

		curr_pos = next_pos
		pts.append(curr_pos)

	return pts
