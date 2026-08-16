class_name NavMeshGenerator

## Generator class that builds NavigationPolygon meshes for stages using exact
## Geometry2D obstacle dilation, spatial partitioning, and T-junction-free
## rectangular (square/quad) meshing. Uses a single background Thread.

const DEFAULT_SUB_STEP: float = 4.0 ## Sub-pixel resolution in pixels (< 16px precision)

const AGENT_TIERS: Array[Dictionary] = [
	{"radius": 10, "layer": 1, "ignore_towers": false}, # Small enemies (< 16px, fits in 16x16 gaps)
	{"radius": 16, "layer": 2, "ignore_towers": false}, # Large enemies (>= 16px, requires wider clearance)
	{"radius": 10, "layer": 4, "ignore_towers": true}, # Ghost enemies (ignores towers, respects stage walls)
]

static var _thread: Thread = null
static var _pending_snapshot: Dictionary = {}
static var _tier_regions: Dictionary = {}

static func get_or_create_tier_region(stage: Stage, layer: int) -> NavigationRegion2D:
	if not is_instance_valid(stage):
		return null
		
	var stage_id = stage.get_instance_id()
	if not _tier_regions.has(stage_id):
		_tier_regions[stage_id] = {}
	
	var regions_for_stage: Dictionary = _tier_regions[stage_id]
	if regions_for_stage.has(layer):
		return regions_for_stage[layer]
	
	if stage.navigation_region_2d and (regions_for_stage.is_empty() or stage.navigation_region_2d.navigation_layers == layer):
		stage.navigation_region_2d.navigation_layers = layer
		regions_for_stage[layer] = stage.navigation_region_2d
		return stage.navigation_region_2d
		
	var new_region = NavigationRegion2D.new()
	new_region.name = "NavRegion_Layer%d" % layer
	new_region.navigation_layers = layer
	stage.add_child(new_region)
	regions_for_stage[layer] = new_region
	return new_region

static func generate_navmesh(
	stage: Stage,
	sub_step: float = DEFAULT_SUB_STEP
) -> void:
	if not stage or not is_instance_valid(stage):
		return

	var tiles: TileMapLayer = stage.tiles
	var towers: Node2D = stage.towers
	var navigation_region_2d: NavigationRegion2D = stage.navigation_region_2d

	if not tiles or not navigation_region_2d:
		return

	var used_cells = tiles.get_used_cells()
	if used_cells.is_empty():
		return

	var tile_size: Vector2 = Vector2(tiles.tile_set.tile_size) * tiles.scale
	var half_tile: Vector2 = tile_size / 2.0

	# Phase 1 (Main Thread): Snapshot node positions/polygons into thread-safe structures
	var walkable_cells_set: Dictionary = {}
	var wall_polys: Array[PackedVector2Array] = []
	var cell_local_centers: Dictionary = {}

	for cell_pos in used_cells:
		var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
		var region_center: Vector2 = navigation_region_2d.to_local(global_center)
		cell_local_centers[cell_pos] = region_center

		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			wall_polys.append(_rect_to_poly(Rect2(region_center - half_tile, tile_size)))
		else:
			walkable_cells_set[cell_pos] = true

	if walkable_cells_set.is_empty():
		return

	var tower_polys: Array[PackedVector2Array] = _extract_tower_polygons(towers, navigation_region_2d)

	var snapshot = {
		"stage": stage,
		"used_cells": used_cells,
		"walkable_cells_set": walkable_cells_set,
		"wall_polys": wall_polys,
		"tower_polys": tower_polys,
		"tile_size": tile_size,
		"cell_local_centers": cell_local_centers,
		"agent_tiers": AGENT_TIERS,
		"sub_step": sub_step
	}

	if _thread and _thread.is_started():
		_pending_snapshot = snapshot
		return

	_thread = Thread.new()
	_thread.start(_thread_worker.bind(snapshot))

static func _thread_worker(snapshot: Dictionary) -> void:
	# Phase 2 (Single Background Thread): Perform geometry dilation, spatial indexing, & greedy quad meshing
	var used_cells = snapshot.used_cells
	var walkable_cells_set: Dictionary = snapshot.walkable_cells_set
	var wall_polys: Array[PackedVector2Array] = snapshot.wall_polys
	var tower_polys: Array[PackedVector2Array] = snapshot.tower_polys
	var tile_size: Vector2 = snapshot.tile_size
	var cell_local_centers: Dictionary = snapshot.cell_local_centers
	var agent_tiers: Array = snapshot.agent_tiers
	var sub_step: float = snapshot.sub_step

	var half_tile: Vector2 = tile_size / 2.0

	var ref_cell: Vector2i = used_cells[0]
	var ref_center: Vector2 = cell_local_centers[ref_cell]

	var min_cell: Vector2i = used_cells[0]
	var max_cell: Vector2i = used_cells[0]
	for cell in used_cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)

	var sub_size: Vector2 = Vector2(sub_step, sub_step)
	var sub_half: Vector2 = sub_size / 2.0
	var subs_per_tile_x: int = roundi(tile_size.x / sub_step)
	var subs_per_tile_y: int = roundi(tile_size.y / sub_step)

	var grid_offset_x = min_cell.x * subs_per_tile_x
	var grid_offset_y = min_cell.y * subs_per_tile_y
	var grid_w = (max_cell.x - min_cell.x + 1) * subs_per_tile_x
	var grid_h = (max_cell.y - min_cell.y + 1) * subs_per_tile_y

	# Calculate grid origin from a known reference tile so missing tiles/holes at min_cell do not crash
	var grid_origin: Vector2 = (ref_center - half_tile) + Vector2(
		(min_cell.x - ref_cell.x) * tile_size.x,
		(min_cell.y - ref_cell.y) * tile_size.y
	)

	var tier_results: Array[Dictionary] = []

	for tier in agent_tiers:
		var tier_radius: float = tier.radius
		var ignore_towers: bool = tier.get("ignore_towers", false)
		var layer: int = tier.layer

		var effective_dilation: float = tier_radius + sub_half.x

		var raw_obstacles: Array[PackedVector2Array] = wall_polys.duplicate()
		if not ignore_towers:
			raw_obstacles.append_array(tower_polys)

		var dilated_obstacles: Array[PackedVector2Array] = []
		var dilated_rects: Array[Rect2] = []

		for obs in raw_obstacles:
			if obs.size() < 3:
				continue
			var ccw_obs = _ensure_ccw(obs)
			var inflated = Geometry2D.offset_polygon(ccw_obs, effective_dilation, Geometry2D.JOIN_SQUARE)
			for inf_poly in inflated:
				var ccw_inf = _ensure_ccw(inf_poly)
				dilated_obstacles.append(ccw_inf)
				dilated_rects.append(_calc_bounding_rect(ccw_inf).grow(1.0))

		# Exact Spatial partition: test obstacle bounding rect against tile cell rect in nav_region local space
		var tile_obstacle_map: Dictionary = {}

		for cell_pos in walkable_cells_set:
			var center: Vector2 = cell_local_centers[cell_pos]
			var cell_rect = Rect2(center - half_tile, tile_size)
			var matches: Array[int] = []

			for obs_idx in range(dilated_rects.size()):
				if dilated_rects[obs_idx].intersects(cell_rect):
					matches.append(obs_idx)

			if not matches.is_empty():
				tile_obstacle_map[cell_pos] = matches

		# Build safe sub-grid
		var safe_grid = PackedByteArray()
		safe_grid.resize(grid_w * grid_h)
		safe_grid.fill(0)

		for cell_pos in walkable_cells_set:
			var relevant_obs_indices: Array = tile_obstacle_map.get(cell_pos, [])

			if relevant_obs_indices.is_empty():
				# Open floor tile: all sub-cells safe
				for sub_x in range(subs_per_tile_x):
					var gx = cell_pos.x * subs_per_tile_x + sub_x - grid_offset_x
					for sub_y in range(subs_per_tile_y):
						var gy = cell_pos.y * subs_per_tile_y + sub_y - grid_offset_y
						safe_grid[gy * grid_w + gx] = 1
			else:
				# Near obstacle: test sub-cells against only intersecting dilated obstacles
				var region_center: Vector2 = cell_local_centers[cell_pos]
				var tile_top_left: Vector2 = region_center - half_tile

				for sub_x in range(subs_per_tile_x):
					var gx = cell_pos.x * subs_per_tile_x + sub_x - grid_offset_x
					for sub_y in range(subs_per_tile_y):
						var gy = cell_pos.y * subs_per_tile_y + sub_y - grid_offset_y
						var sub_center: Vector2 = tile_top_left + Vector2(
							sub_x * sub_step + sub_half.x,
							sub_y * sub_step + sub_half.y
						)

						var is_safe = true
						for obs_idx in relevant_obs_indices:
							if dilated_rects[obs_idx].has_point(sub_center):
								if Geometry2D.is_point_in_polygon(sub_center, dilated_obstacles[obs_idx]):
									is_safe = false
									break

						if is_safe:
							safe_grid[gy * grid_w + gx] = 1

		# Greedy Meshing Pass 1
		var greedy_rects: Array[Rect2i] = []
		var corners_set: Dictionary = {}

		for y in range(grid_h):
			for x in range(grid_w):
				if safe_grid[y * grid_w + x] == 1:
					var w = 1
					while x + w < grid_w and safe_grid[y * grid_w + (x + w)] == 1:
						w += 1

					var h = 1
					var can_expand_h = true
					while y + h < grid_h and can_expand_h:
						for dx in range(w):
							if safe_grid[(y + h) * grid_w + (x + dx)] == 0:
								can_expand_h = false
								break
						if can_expand_h:
							h += 1

					for dy in range(h):
						for dx in range(w):
							safe_grid[(y + dy) * grid_w + (x + dx)] = 0

					greedy_rects.append(Rect2i(x, y, w, h))

					corners_set[Vector2i(x, y)] = true
					corners_set[Vector2i(x + w, y)] = true
					corners_set[Vector2i(x + w, y + h)] = true
					corners_set[Vector2i(x, y + h)] = true

		# Greedy Meshing Pass 2
		var vertex_map: Dictionary = {}
		var all_vertices: PackedVector2Array = []

		var get_vertex_idx = func(pos: Vector2) -> int:
			var key = Vector2(snappedf(pos.x, 0.01), snappedf(pos.y, 0.01))
			var idx = vertex_map.get(key, -1)
			if idx != -1: return idx
			idx = all_vertices.size()
			all_vertices.append(pos)
			vertex_map[key] = idx
			return idx

		var polygons: Array[PackedInt32Array] = []

		for rect in greedy_rects:
			var x = rect.position.x
			var y = rect.position.y
			var w = rect.size.x
			var h = rect.size.y

			var poly_points = PackedInt32Array()

			for gx in range(x, x + w):
				if corners_set.has(Vector2i(gx, y)):
					var pt = grid_origin + Vector2(gx * sub_step, y * sub_step)
					poly_points.append(get_vertex_idx.call(pt))

			for gy in range(y, y + h):
				if corners_set.has(Vector2i(x + w, gy)):
					var pt = grid_origin + Vector2((x + w) * sub_step, gy * sub_step)
					poly_points.append(get_vertex_idx.call(pt))

			for gx in range(x + w, x, -1):
				if corners_set.has(Vector2i(gx, y + h)):
					var pt = grid_origin + Vector2(gx * sub_step, (y + h) * sub_step)
					poly_points.append(get_vertex_idx.call(pt))

			for gy in range(y + h, y, -1):
				if corners_set.has(Vector2i(x, gy)):
					var pt = grid_origin + Vector2(x * sub_step, gy * sub_step)
					poly_points.append(get_vertex_idx.call(pt))

			polygons.append(poly_points)

		tier_results.append({
			"layer": layer,
			"vertices": all_vertices,
			"polygons": polygons
		})

	# Phase 3: Pass results back to main thread via deferred call
	var stage = snapshot.stage
	Callable(_apply_results_on_main_thread).call_deferred(tier_results, stage)

static func _apply_results_on_main_thread(tier_results: Array[Dictionary], stage: Stage) -> void:
	if is_instance_valid(stage):
		for res in tier_results:
			var layer: int = res.layer
			var vertices: PackedVector2Array = res.vertices
			var polygons: Array = res.polygons

			var nav_poly: NavigationPolygon = NavigationPolygon.new()
			nav_poly.vertices = vertices
			for poly in polygons:
				nav_poly.add_polygon(poly)

			var tier_region: NavigationRegion2D = get_or_create_tier_region(stage, layer)
			if tier_region:
				tier_region.navigation_polygon = nav_poly

		SignalBus.navmesh_updated.emit()

	if _thread and _thread.is_started():

		_thread.wait_to_finish()
	_thread = null

	if not _pending_snapshot.is_empty():
		var next_snap = _pending_snapshot.duplicate()
		_pending_snapshot.clear()
		_thread = Thread.new()
		_thread.start(_thread_worker.bind(next_snap))

static func _calc_bounding_rect(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_pt = poly[0]
	var max_pt = poly[0]
	for i in range(1, poly.size()):
		var pt = poly[i]
		min_pt.x = minf(min_pt.x, pt.x)
		min_pt.y = minf(min_pt.y, pt.y)
		max_pt.x = maxf(max_pt.x, pt.x)
		max_pt.y = maxf(max_pt.y, pt.y)
	return Rect2(min_pt, max_pt - min_pt)

static func _rect_to_poly(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x, rect.end.y),
		Vector2(rect.end.x, rect.end.y),
		Vector2(rect.end.x, rect.position.y)
	])

static func _ensure_ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(poly):
		var res = poly.duplicate()
		res.reverse()
		return res
	return poly

static func _extract_tower_polygons(towers: Node2D, nav_region: NavigationRegion2D) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if not towers:
		return result

	for tower in towers.get_children():
		if tower is Tower and not tower.is_queued_for_deletion() and not tower.is_preview and (tower.collision_layer > 0 or (tower.data and tower.data.collision_layer > 0)):
			var found_shape = false

			for child in tower.get_children():
				if child is CollisionShape2D and child.shape is RectangleShape2D:
					var rect_shape: RectangleShape2D = child.shape
					var size: Vector2 = rect_shape.size
					var half_size: Vector2 = size / 2.0

					var local_corners = [
						Vector2(-half_size.x, -half_size.y),
						Vector2(-half_size.x, half_size.y),
						Vector2(half_size.x, half_size.y),
						Vector2(half_size.x, -half_size.y)
					]

					var poly = PackedVector2Array()
					for pt in local_corners:
						var g_pt = child.to_global(pt)
						poly.append(nav_region.to_local(g_pt))

					result.append(_ensure_ccw(poly))
					found_shape = true
					break
				elif child is CollisionPolygon2D:
					var poly = PackedVector2Array()
					for pt in child.polygon:
						var g_pt = child.to_global(pt)
						poly.append(nav_region.to_local(g_pt))
					result.append(_ensure_ccw(poly))
					found_shape = true
					break

			if not found_shape:
				var half_size = Vector2(32, 32)
				var local_corners = [
					Vector2(-half_size.x, -half_size.y),
					Vector2(-half_size.x, half_size.y),
					Vector2(half_size.x, half_size.y),
					Vector2(half_size.x, -half_size.y)
				]
				var poly = PackedVector2Array()
				for pt in local_corners:
					var g_pt = tower.to_global(pt)
					poly.append(nav_region.to_local(g_pt))
				result.append(_ensure_ccw(poly))

	return result
