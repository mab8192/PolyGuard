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

	func pop(out: Array) -> bool:
		if size == 0:
			return false
		out[0] = costs[0]
		out[1] = indices[0]
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

func set_cell_cost(gx: int, gy: int, cost: float) -> void:
	if is_valid_cell(gx, gy):
		base_cost[gy * grid_size.x + gx] = cost

func set_rect_cost(rect: Rect2, cost: float, min_overlap_ratio: float = 0.0) -> void:
	var min_cell = global_to_grid(rect.position)
	var max_cell = global_to_grid(rect.end - Vector2(0.001, 0.001))
	var cell_area = cell_size.x * cell_size.y

	for gy in range(min_cell.y, max_cell.y + 1):
		if gy < 0 or gy >= grid_size.y:
			continue
		var cell_y0 = world_origin.y + float(gy) * cell_size.y
		var cell_y1 = cell_y0 + cell_size.y
		var overlap_y0 = maxf(rect.position.y, cell_y0)
		var overlap_y1 = minf(rect.end.y, cell_y1)
		var overlap_h = maxf(0.0, overlap_y1 - overlap_y0)
		if overlap_h <= 0.0:
			continue

		var row_offset = gy * grid_size.x
		for gx in range(min_cell.x, max_cell.x + 1):
			if gx < 0 or gx >= grid_size.x:
				continue
			var cell_x0 = world_origin.x + float(gx) * cell_size.x
			var cell_x1 = cell_x0 + cell_size.x
			var overlap_x0 = maxf(rect.position.x, cell_x0)
			var overlap_x1 = minf(rect.end.x, cell_x1)
			var overlap_w = maxf(0.0, overlap_x1 - overlap_x0)

			if overlap_w > 0.0:
				if min_overlap_ratio > 0.0:
					var ratio = (overlap_w * overlap_h) / cell_area
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
	var local = world_pos - world_origin
	var gx = int(floor(local.x / cell_size.x))
	var gy = int(floor(local.y / cell_size.y))
	if is_valid_cell(gx, gy):
		var idx = gy * grid_size.x + gx
		if integration_cost[idx] < TOWER_COST:
			return true

	# Check a 1-cell neighborhood around world_pos to prevent false negatives near boundaries
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = gx + dx
			var ny = gy + dy
			if is_valid_cell(nx, ny):
				if integration_cost[ny * grid_size.x + nx] < TOWER_COST:
					return true
	return false

func is_reachable(world_pos: Vector2) -> bool:
	if total_cells == 0:
		return false
	var local = world_pos - world_origin
	var gx = int(floor(local.x / cell_size.x))
	var gy = int(floor(local.y / cell_size.y))
	if is_valid_cell(gx, gy):
		var idx = gy * grid_size.x + gx
		if integration_cost[idx] < BLOCKED_COST:
			return true

	# Check a 1-cell neighborhood around world_pos to prevent false unreachability near boundary hitboxes
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = gx + dx
			var ny = gy + dy
			if is_valid_cell(nx, ny):
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
	var cs_x = cell_size.x
	var cs_y = cell_size.y

	for target_pos in target_positions:
		var local = target_pos - world_origin
		var cx = int(floor(local.x / cs_x))
		var cy = int(floor(local.y / cs_y))

		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var gx = cx + dx
				var gy = cy + dy
				if gx >= 0 and gx < w and gy >= 0 and gy < h:
					var idx = gy * w + gx
					if base_cost[idx] < BLOCKED_COST:
						var cell_center = world_origin + Vector2((float(gx) + 0.5) * cs_x, (float(gy) + 0.5) * cs_y)
						var initial_dist = target_pos.distance_to(cell_center) / cs_x
						if initial_dist < integration_cost[idx]:
							integration_cost[idx] = initial_dist
							_heap.push(initial_dist, idx)

	const NEIGHBORS = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	const DIST_MULT = [1.0, 1.0, 1.0, 1.0, SQRT_2, SQRT_2, SQRT_2, SQRT_2]

	var pop_out: Array = [0.0, 0]
	while _heap.pop(pop_out):
		var pop_cost: float = pop_out[0]
		var curr_idx: int = pop_out[1]

		# Stale entry pruning
		if pop_cost > integration_cost[curr_idx]:
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

			# Diagonal corner-cutting safety check: prevent cutting across walls or towers
			if i >= 4:
				if base_cost[gy * w + nx] >= TOWER_COST or base_cost[ny * w + gx] >= TOWER_COST:
					continue

			# Effective cell cost includes dynamic enemy congestion
			var cell_cost = n_base + congestion_cost[n_idx]
			var tentative_dist = pop_cost + cell_cost * DIST_MULT[i]

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
			elif has_right and not has_left:
				if integration_cost[idx + 1] < curr_cost:
					grad_x = curr_cost - integration_cost[idx + 1]

			# Y-axis gradient: points downhill (cost(up) - cost(down))
			if has_up and has_down:
				grad_y = integration_cost[idx - w] - integration_cost[idx + w]
			elif has_up and not has_down:
				if integration_cost[idx - w] < curr_cost:
					grad_y = integration_cost[idx - w] - curr_cost
			elif has_down and not has_up:
				if integration_cost[idx + w] < curr_cost:
					grad_y = curr_cost - integration_cost[idx + w]

			var grad_len_sq = grad_x * grad_x + grad_y * grad_y
			if grad_len_sq > 0.000001:
				var inv_l = 1.0 / sqrt(grad_len_sq)
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
					if base_cost[row_offset + nx] >= TOWER_COST or base_cost[ny * w + gx] >= TOWER_COST:
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

## Smooth Bilinear Vector Sampling with Non-Zero Neighbor Blending
func sample_direction(world_pos: Vector2) -> Vector2:
	if total_cells == 0:
		return Vector2.ZERO

	var local = (world_pos - world_origin - cell_size * 0.5) / cell_size
	var x0 = int(floor(local.x))
	var y0 = int(floor(local.y))
	var tx = clampf(local.x - float(x0), 0.0, 1.0)
	var ty = clampf(local.y - float(y0), 0.0, 1.0)

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

	var w00 = (1.0 - tx) * (1.0 - ty)
	var w10 = tx * (1.0 - ty)
	var w01 = (1.0 - tx) * ty
	var w11 = tx * ty

	var blended_dir = Vector2.ZERO
	var total_weight = 0.0

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
	var gx = clampi(int(floor((world_pos.x - world_origin.x) / cell_size.x)), 0, w - 1)
	var gy = clampi(int(floor((world_pos.y - world_origin.y) / cell_size.y)), 0, h - 1)
	var base_dir = flow_vectors[gy * w + gx]
	if base_dir.length_squared() > 0.0001:
		return base_dir.normalized()

	return Vector2.ZERO

## Traces a continuous path streamline from start_pos to the closest exit using RK2 integration.
func trace_path(start_pos: Vector2, step_size: float = 8.0, max_steps: int = 400, exit_nodes: Array[Node2D] = []) -> PackedVector2Array:
	var pts = PackedVector2Array([start_pos])
	var curr_pos = start_pos
	const EXIT_REACH_RADIUS_SQ: float = 54.0 * 54.0 ## Covers 64x64 exit area

	var last_grid = Vector2i(-999, -999)
	var same_cell_steps = 0

	for _step in range(max_steps):
		for exit in exit_nodes:
			if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= EXIT_REACH_RADIUS_SQ:
				pts.append(exit.global_position)
				return pts

		var k1 = sample_direction(curr_pos)
		if k1 == Vector2.ZERO:
			# If flow vector reached terminal zero near an exit, connect directly to closest exit
			for exit in exit_nodes:
				if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= 80.0 * 80.0:
					pts.append(exit.global_position)
					return pts
			break

		# 2nd-order Runge-Kutta (RK2 midpoint) integration for smooth curvature
		var mid_pos = curr_pos + k1 * (step_size * 0.5)
		var k2 = sample_direction(mid_pos)
		var step_dir = k2 if k2 != Vector2.ZERO else k1

		var next_pos = curr_pos + step_dir * step_size

		# If stepping into a permanent wall, slide along valid direction
		var g = global_to_grid(next_pos)
		if is_valid_cell(g.x, g.y):
			if base_cost[grid_to_index(g.x, g.y)] >= BLOCKED_COST:
				var slide_dir = sample_direction(curr_pos)
				if slide_dir != Vector2.ZERO:
					next_pos = curr_pos + slide_dir * (step_size * 0.5)
					var g_slide = global_to_grid(next_pos)
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
	for exit in exit_nodes:
		if is_instance_valid(exit) and curr_pos.distance_squared_to(exit.global_position) <= EXIT_REACH_RADIUS_SQ:
			pts.append(exit.global_position)
			break

	return pts
