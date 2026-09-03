class_name RangeVisualizer

const RANGE_BORDER_COLOR: Color = Color(0.0, 0.96, 0.83, 0.95)
const RANGE_FILL_COLOR: Color = Color(0.0, 0.96, 0.83, 0.12)
const RANGE_BORDER_WIDTH: float = 2.5

const BLOCKED_RANGE_FILL_COLOR: Color = Color(1.0, 0.18, 0.18, 0.15)
const BLOCKED_RANGE_BORDER_COLOR: Color = Color(1.0, 0.25, 0.25, 0.85)

## Discovers the physical attack/firing origin in global coordinates
static func get_targeting_origin_global(component: CanvasItem) -> Vector2:
	var parent := component.get_parent()
	if parent:
		var markers: Array[Marker2D] = []
		for child in parent.get_children():
			if child is Marker2D:
				markers.append(child)
		if not markers.is_empty():
			var sum := Vector2.ZERO
			for m in markers:
				sum += m.global_position
			return sum / float(markers.size())

		for child in parent.get_children():
			if child is CPUParticles2D or child is GPUParticles2D:
				return child.global_position

		for child in parent.get_children():
			if child is CollisionShape2D and child != component:
				return child.global_position
	return (component as Node2D).global_position if component is Node2D else Vector2.ZERO

## Checks line of sight between an origin and a target node
static func has_line_of_sight(from_pos: Vector2, target: Node2D, context: CanvasItem, exclude_object: CollisionObject2D = null) -> bool:
	if not is_instance_valid(target):
		return false
	var space_state := context.get_world_2d().direct_space_state if context.get_world_2d() else null
	if not space_state:
		return true

	var query := PhysicsRayQueryParameters2D.create(from_pos, target.global_position, 1) # Layer 1: Walls
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var exclude: Array[RID] = []
	if exclude_object:
		exclude.append(exclude_object.get_rid())
	elif context.owner is CollisionObject2D:
		exclude.append((context.owner as CollisionObject2D).get_rid())
	elif context.get_parent() is CollisionObject2D:
		exclude.append((context.get_parent() as CollisionObject2D).get_rid())
	query.exclude = exclude

	var hit := space_state.intersect_ray(query)
	return hit.is_empty()

## Draws the full range collider visual for a component
static func draw_range(component: CanvasItem, can_target_through_walls: bool) -> void:
	var origin_global := get_targeting_origin_global(component)
	for child in component.get_children():
		if child is CollisionShape2D:
			var col_shape := child as CollisionShape2D
			if col_shape.disabled or not col_shape.shape:
				continue
			component.draw_set_transform(col_shape.position, col_shape.rotation, col_shape.scale)
			draw_shape_with_occlusion(component, col_shape, col_shape.shape, can_target_through_walls, origin_global)
			component.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif child is CollisionPolygon2D:
			var col_poly := child as CollisionPolygon2D
			if col_poly.disabled or col_poly.polygon.is_empty():
				continue
			component.draw_set_transform(col_poly.position, col_poly.rotation, col_poly.scale)
			draw_polygon_with_occlusion(component, col_poly, col_poly.polygon, can_target_through_walls, origin_global)
			component.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func draw_shape_with_occlusion(component: CanvasItem, node: Node2D, shape: Shape2D, can_target_through_walls: bool, origin_global: Vector2) -> void:
	if can_target_through_walls or not component.is_inside_tree():
		draw_shape_unobstructed(component, shape)
		return

	var space_state: PhysicsDirectSpaceState2D = component.get_world_2d().direct_space_state if component.get_world_2d() else null
	if not space_state:
		draw_shape_unobstructed(component, shape)
		return

	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		_draw_circle_occluded(component, node, circle.radius, space_state, origin_global)
	elif shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		_draw_rect_occluded(component, node, rect_shape.size, space_state, origin_global)
	elif shape is CapsuleShape2D:
		var cap := shape as CapsuleShape2D
		_draw_capsule_occluded(component, node, cap.radius, cap.height, space_state, origin_global)
	elif shape is ConvexPolygonShape2D:
		var convex := shape as ConvexPolygonShape2D
		_draw_polygon_occluded(component, node, convex.points, space_state, origin_global)
	else:
		draw_shape_unobstructed(component, shape)

static func draw_polygon_with_occlusion(component: CanvasItem, node: Node2D, poly: PackedVector2Array, can_target_through_walls: bool, origin_global: Vector2) -> void:
	if can_target_through_walls or not component.is_inside_tree():
		draw_polygon_unobstructed(component, poly)
		return

	var space_state: PhysicsDirectSpaceState2D = component.get_world_2d().direct_space_state if component.get_world_2d() else null
	if not space_state:
		draw_polygon_unobstructed(component, poly)
		return

	_draw_polygon_occluded(component, node, poly, space_state, origin_global)

static func _get_tile_map_layer(context: CanvasItem) -> TileMapLayer:
	if GameManager.current_stage and is_instance_valid(GameManager.current_stage.tiles):
		return GameManager.current_stage.tiles
	if context.is_inside_tree() and context.get_tree().current_scene:
		var node = context.get_tree().current_scene.find_child("Tiles", true, false)
		if node is TileMapLayer:
			return node
	return null

static func _collect_wall_corner_angles(context: CanvasItem, origin_global: Vector2, radius: float, angles: Array[float]) -> void:
	var tiles := _get_tile_map_layer(context)
	if not tiles or not tiles.is_inside_tree():
		return

	var margin := 64.0
	var min_cell := tiles.local_to_map(tiles.to_local(origin_global - Vector2(radius + margin, radius + margin)))
	var max_cell := tiles.local_to_map(tiles.to_local(origin_global + Vector2(radius + margin, radius + margin)))

	for cx in range(min_cell.x, max_cell.x + 1):
		for cy in range(min_cell.y, max_cell.y + 1):
			var cell_pos := Vector2i(cx, cy)
			var tile_data := tiles.get_cell_tile_data(cell_pos)
			if not tile_data or tile_data.get_collision_polygons_count(0) == 0:
				continue

			var cell_local_center := tiles.map_to_local(cell_pos)
			var poly_count := tile_data.get_collision_polygons_count(0)
			for p in range(poly_count):
				var pts := tile_data.get_collision_polygon_points(0, p)
				var pt_count := pts.size()
				for idx in range(pt_count):
					var p1 := pts[idx]
					var p2 := pts[(idx + 1) % pt_count]
					var g_p1 := tiles.to_global(cell_local_center + p1)
					var g_p2 := tiles.to_global(cell_local_center + p2)

					# 1. Corner vertices
					var diff1 := g_p1 - origin_global
					var dist1_sq := diff1.length_squared()
					if dist1_sq <= (radius + margin) * (radius + margin) and dist1_sq > 0.01:
						angles.append(atan2(diff1.y, diff1.x))

					# 2. Impute exact intersection points where wall edge crosses range boundary
					var edge := g_p2 - g_p1
					var a := edge.length_squared()
					if a > 0.0001:
						var v := g_p1 - origin_global
						var b := 2.0 * v.dot(edge)
						var c := v.length_squared() - radius * radius
						var disc := b * b - 4.0 * a * c
						if disc >= 0.0:
							var sqrt_disc := sqrt(disc)
							var t1 := (-b - sqrt_disc) / (2.0 * a)
							var t2 := (-b + sqrt_disc) / (2.0 * a)
							if t1 >= -0.001 and t1 <= 1.001:
								var inter1 := g_p1 + edge * clampf(t1, 0.0, 1.0) - origin_global
								angles.append(atan2(inter1.y, inter1.x))
							if t2 >= -0.001 and t2 <= 1.001:
								var inter2 := g_p1 + edge * clampf(t2, 0.0, 1.0) - origin_global
								angles.append(atan2(inter2.y, inter2.x))

static func _draw_ray_sweep(
	component: CanvasItem,
	node: Node2D,
	angles: Array[float],
	origin_local: Vector2,
	origin_global: Vector2,
	space_state: PhysicsDirectSpaceState2D,
	get_boundary_pt: Callable
) -> void:
	if angles.is_empty():
		return

	# 1. Deduplicate and sort angles in [0, TAU)
	for i in range(angles.size()):
		angles[i] = fposmod(angles[i], TAU)
	angles.sort()

	var unique_angles: Array[float] = []
	for i in range(angles.size()):
		if unique_angles.is_empty() or absf(angles[i] - unique_angles.back()) > 0.00005:
			unique_angles.append(angles[i])

	var count := unique_angles.size()
	if count < 3:
		return

	# 2. Compute boundary points
	var perimeter_pts: PackedVector2Array = []
	perimeter_pts.resize(count)
	for i in range(count):
		var ang := unique_angles[i]
		var dir := Vector2(cos(ang), sin(ang))
		perimeter_pts[i] = get_boundary_pt.call(origin_local, dir)

	# 3. Raycast to determine visible points and blocked status
	var visible_pts: PackedVector2Array = []
	visible_pts.resize(count)
	var is_blocked: Array[bool] = []
	is_blocked.resize(count)

	var exclude_rids: Array[RID] = []
	if component.owner is CollisionObject2D:
		exclude_rids.append((component.owner as CollisionObject2D).get_rid())
	elif component.get_parent() is CollisionObject2D:
		exclude_rids.append((component.get_parent() as CollisionObject2D).get_rid())

	for i in range(count):
		var local_end := perimeter_pts[i]
		var global_end := node.to_global(local_end)
		var query := PhysicsRayQueryParameters2D.create(origin_global, global_end, 1) # Layer 1: Walls
		query.collide_with_areas = false
		query.collide_with_bodies = true
		if not exclude_rids.is_empty():
			query.exclude = exclude_rids

		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_dist_sq := origin_global.distance_squared_to(hit.position)
			var total_dist_sq := origin_global.distance_squared_to(global_end)
			if hit_dist_sq < total_dist_sq - 4.0:
				visible_pts[i] = node.to_local(hit.position)
				is_blocked[i] = true
			else:
				visible_pts[i] = local_end
				is_blocked[i] = false
		else:
			visible_pts[i] = local_end
			is_blocked[i] = false

	# 4. Render slices slice-by-slice as guaranteed primitive triangles
	for i in range(count):
		var j := (i + 1) % count
		var end_i := perimeter_pts[i]
		var end_j := perimeter_pts[j]
		var vis_i := visible_pts[i]
		var vis_j := visible_pts[j]

		# Visible triangle: (origin_local, vis_i, vis_j)
		var vis_area := 0.5 * absf((vis_i.x - origin_local.x) * (vis_j.y - origin_local.y) - (vis_j.x - origin_local.x) * (vis_i.y - origin_local.y))
		if vis_area > 0.05:
			component.draw_colored_polygon(PackedVector2Array([origin_local, vis_i, vis_j]), RANGE_FILL_COLOR)

		# Blocked triangles clamped to wall edges
		if is_blocked[i] and is_blocked[j]:
			var area_b1 := 0.5 * absf((end_i.x - vis_i.x) * (end_j.y - vis_i.y) - (end_j.x - vis_i.x) * (end_i.y - vis_i.y))
			if area_b1 > 0.05:
				component.draw_colored_polygon(PackedVector2Array([vis_i, end_i, end_j]), BLOCKED_RANGE_FILL_COLOR)

			var area_b2 := 0.5 * absf((end_j.x - vis_i.x) * (vis_j.y - vis_i.y) - (vis_j.x - vis_i.x) * (end_j.y - vis_i.y))
			if area_b2 > 0.05:
				component.draw_colored_polygon(PackedVector2Array([vis_i, end_j, vis_j]), BLOCKED_RANGE_FILL_COLOR)

			# Wall shadow boundary line along wall front
			component.draw_line(vis_i, vis_j, BLOCKED_RANGE_BORDER_COLOR, 1.5, true)
			component.draw_line(end_i, end_j, BLOCKED_RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
		elif is_blocked[i] or is_blocked[j]:
			# Transition slice: keep outer boundary color intact so red does not float outside wall
			if is_blocked[i]:
				var area_t := 0.5 * absf((end_i.x - vis_i.x) * (end_j.y - vis_i.y) - (end_j.x - vis_i.x) * (end_i.y - vis_i.y))
				if area_t > 0.05:
					component.draw_colored_polygon(PackedVector2Array([vis_i, end_i, end_j]), BLOCKED_RANGE_FILL_COLOR)
			else:
				var area_t := 0.5 * absf((end_j.x - vis_j.x) * (end_i.y - vis_j.y) - (end_i.x - vis_j.x) * (end_j.y - vis_j.y))
				if area_t > 0.05:
					component.draw_colored_polygon(PackedVector2Array([vis_j, end_i, end_j]), BLOCKED_RANGE_FILL_COLOR)
			component.draw_line(end_i, end_j, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
		else:
			component.draw_line(end_i, end_j, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)

static func _draw_circle_occluded(component: CanvasItem, node: Node2D, radius: float, space_state: PhysicsDirectSpaceState2D, origin_global: Vector2) -> void:
	var origin_local := node.to_local(origin_global)
	var angles: Array[float] = []
	var base_segments := 96
	for i in range(base_segments):
		angles.append(i * TAU / float(base_segments))

	var corner_world_angles: Array[float] = []
	_collect_wall_corner_angles(component, origin_global, radius + origin_local.length(), corner_world_angles)
	for ang in corner_world_angles:
		var world_dir := Vector2(cos(ang), sin(ang))
		var local_dir := (node.to_local(origin_global + world_dir) - origin_local).normalized()
		var local_ang := atan2(local_dir.y, local_dir.x)
		angles.append(local_ang - 0.0003)
		angles.append(local_ang)
		angles.append(local_ang + 0.0003)

	var get_pt := func(orig: Vector2, dir: Vector2) -> Vector2:
		if orig.length_squared() < 0.01:
			return dir * radius
		var b := orig.dot(dir)
		var c := orig.length_squared() - radius * radius
		var disc := b * b - c
		if disc >= 0.0:
			var t := -b + sqrt(disc)
			return orig + dir * maxf(t, 0.0)
		return dir * radius

	_draw_ray_sweep(component, node, angles, origin_local, origin_global, space_state, get_pt)

static func _get_ray_rect_intersection(origin: Vector2, dir: Vector2, rect: Rect2) -> Vector2:
	var min_p := rect.position
	var max_p := rect.end
	var t_near := -INF
	var t_far := INF

	if absf(dir.x) > 0.00001:
		var t1 := (min_p.x - origin.x) / dir.x
		var t2 := (max_p.x - origin.x) / dir.x
		var t_min := minf(t1, t2)
		var t_max := maxf(t1, t2)
		t_near = maxf(t_near, t_min)
		t_far = minf(t_far, t_max)
	elif origin.x < min_p.x or origin.x > max_p.x:
		return origin + dir * 100.0

	if absf(dir.y) > 0.00001:
		var t1 := (min_p.y - origin.y) / dir.y
		var t2 := (max_p.y - origin.y) / dir.y
		var t_min := minf(t1, t2)
		var t_max := maxf(t1, t2)
		t_near = maxf(t_near, t_min)
		t_far = minf(t_far, t_max)
	elif origin.y < min_p.y or origin.y > max_p.y:
		return origin + dir * 100.0

	var t := t_far if t_far > 0.0 else (t_near if t_near > 0.0 else 0.0)
	return origin + dir * t

static func _draw_rect_occluded(component: CanvasItem, node: Node2D, size: Vector2, space_state: PhysicsDirectSpaceState2D, origin_global: Vector2) -> void:
	var origin_local := node.to_local(origin_global)
	var half := size / 2.0
	var rect := Rect2(-half, size)
	var max_dim := size.length() + origin_local.length()

	var angles: Array[float] = []
	var side_segments := 24
	for i in range(side_segments):
		var p := Vector2(lerpf(-half.x, half.x, float(i) / float(side_segments)), -half.y)
		angles.append(atan2(p.y - origin_local.y, p.x - origin_local.x))
	for i in range(side_segments):
		var p := Vector2(half.x, lerpf(-half.y, half.y, float(i) / float(side_segments)))
		angles.append(atan2(p.y - origin_local.y, p.x - origin_local.x))
	for i in range(side_segments):
		var p := Vector2(lerpf(half.x, -half.x, float(i) / float(side_segments)), half.y)
		angles.append(atan2(p.y - origin_local.y, p.x - origin_local.x))
	for i in range(side_segments):
		var p := Vector2(-half.x, lerpf(half.y, -half.y, float(i) / float(side_segments)))
		angles.append(atan2(p.y - origin_local.y, p.x - origin_local.x))

	var corners := [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
	for c in corners:
		var ang := atan2(c.y - origin_local.y, c.x - origin_local.x)
		angles.append(ang - 0.0003)
		angles.append(ang + 0.0003)

	var corner_world_angles: Array[float] = []
	_collect_wall_corner_angles(component, origin_global, max_dim, corner_world_angles)
	for ang in corner_world_angles:
		var world_dir := Vector2(cos(ang), sin(ang))
		var local_dir := (node.to_local(origin_global + world_dir) - origin_local).normalized()
		var local_ang := atan2(local_dir.y, local_dir.x)
		angles.append(local_ang - 0.0003)
		angles.append(local_ang)
		angles.append(local_ang + 0.0003)

	var get_pt := func(orig: Vector2, dir: Vector2) -> Vector2:
		return _get_ray_rect_intersection(orig, dir, rect)

	_draw_ray_sweep(component, node, angles, origin_local, origin_global, space_state, get_pt)

static func _get_ray_capsule_intersection(origin: Vector2, dir: Vector2, radius: float, half_h: float) -> Vector2:
	var best_t := -INF
	var fallback := origin + dir * (radius + half_h)

	# 1. Left line segment x = -radius, y in [-half_h, half_h]
	if absf(dir.x) > 0.00001:
		var t := (-radius - origin.x) / dir.x
		if t > 0.0:
			var py := origin.y + dir.y * t
			if py >= -half_h - 0.001 and py <= half_h + 0.001:
				if t > best_t:
					best_t = t
					fallback = origin + dir * t

	# 2. Right line segment x = radius, y in [-half_h, half_h]
	if absf(dir.x) > 0.00001:
		var t := (radius - origin.x) / dir.x
		if t > 0.0:
			var py := origin.y + dir.y * t
			if py >= -half_h - 0.001 and py <= half_h + 0.001:
				if t > best_t:
					best_t = t
					fallback = origin + dir * t

	# 3. Top semicircle center (0, -half_h)
	var c_top := Vector2(0.0, -half_h)
	var diff_top := origin - c_top
	var b_top := diff_top.dot(dir)
	var c_val_top := diff_top.length_squared() - radius * radius
	var disc_top := b_top * b_top - c_val_top
	if disc_top >= 0.0:
		var t := -b_top + sqrt(disc_top)
		if t > 0.0:
			var py := origin.y + dir.y * t
			if py <= -half_h + 0.001:
				if t > best_t:
					best_t = t
					fallback = origin + dir * t

	# 4. Bottom semicircle center (0, half_h)
	var c_bot := Vector2(0.0, half_h)
	var diff_bot := origin - c_bot
	var b_bot := diff_bot.dot(dir)
	var c_val_bot := diff_bot.length_squared() - radius * radius
	var disc_bot := b_bot * b_bot - c_val_bot
	if disc_bot >= 0.0:
		var t := -b_bot + sqrt(disc_bot)
		if t > 0.0:
			var py := origin.y + dir.y * t
			if py >= half_h - 0.001:
				if t > best_t:
					best_t = t
					fallback = origin + dir * t

	return fallback

static func _draw_capsule_occluded(component: CanvasItem, node: Node2D, radius: float, height: float, space_state: PhysicsDirectSpaceState2D, origin_global: Vector2) -> void:
	var origin_local := node.to_local(origin_global)
	var half_h := maxf(0.0, (height / 2.0) - radius)
	var max_dim := radius + half_h + origin_local.length()

	var angles: Array[float] = []
	var segments := 48
	for i in range(segments):
		var angle := PI + (PI * i / float(segments))
		var p := Vector2(cos(angle) * radius, -half_h + sin(angle) * radius)
		angles.append(atan2(p.y - origin_local.y, p.x - origin_local.x))
	for i in range(segments):
		var angle := (PI * i / float(segments))
		var p := Vector2(cos(angle) * radius, half_h + sin(angle) * radius)
		angles.append(atan2(p.y - origin_local.y, p.x - origin_local.x))

	var corner_world_angles: Array[float] = []
	_collect_wall_corner_angles(component, origin_global, max_dim, corner_world_angles)
	for ang in corner_world_angles:
		var world_dir := Vector2(cos(ang), sin(ang))
		var local_dir := (node.to_local(origin_global + world_dir) - origin_local).normalized()
		var local_ang := atan2(local_dir.y, local_dir.x)
		angles.append(local_ang - 0.0003)
		angles.append(local_ang)
		angles.append(local_ang + 0.0003)

	var get_pt := func(orig: Vector2, dir: Vector2) -> Vector2:
		return _get_ray_capsule_intersection(orig, dir, radius, half_h)

	_draw_ray_sweep(component, node, angles, origin_local, origin_global, space_state, get_pt)

static func _get_ray_polygon_intersection(origin: Vector2, dir: Vector2, poly: PackedVector2Array) -> Vector2:
	var count := poly.size()
	var best_t := -INF
	var fallback := origin + dir * 100.0

	for i in range(count):
		var p1 := poly[i]
		var p2 := poly[(i + 1) % count]
		var edge := p2 - p1
		var denom := dir.x * edge.y - dir.y * edge.x
		if absf(denom) < 0.00001:
			continue
		var diff := p1 - origin
		var t := (diff.x * edge.y - diff.y * edge.x) / denom
		var u := (diff.x * dir.y - diff.y * dir.x) / denom
		if t > 0.0001 and u >= -0.001 and u <= 1.001:
			if t > best_t:
				best_t = t
				fallback = origin + dir * t

	return fallback

static func _draw_polygon_occluded(component: CanvasItem, node: Node2D, poly: PackedVector2Array, space_state: PhysicsDirectSpaceState2D, origin_global: Vector2) -> void:
	if poly.size() < 3:
		return
	var origin_local := node.to_local(origin_global)
	var count := poly.size()
	var max_dim := 0.0
	for p in poly:
		max_dim = maxf(max_dim, origin_local.distance_to(p))

	var angles: Array[float] = []

	var base_segments := 64
	for i in range(base_segments):
		angles.append(i * TAU / float(base_segments))

	var samples_per_edge := 16
	for i in range(count):
		var p1 := poly[i]
		var p2 := poly[(i + 1) % count]
		var ang_v := atan2(p1.y - origin_local.y, p1.x - origin_local.x)
		angles.append(ang_v - 0.0003)
		angles.append(ang_v)
		angles.append(ang_v + 0.0003)

		for s in range(1, samples_per_edge):
			var t := float(s) / float(samples_per_edge)
			var p := p1.lerp(p2, t)
			angles.append(atan2(p.y - origin_local.y, p.x - origin_local.x))

	var corner_world_angles: Array[float] = []
	_collect_wall_corner_angles(component, origin_global, max_dim, corner_world_angles)
	for ang in corner_world_angles:
		var world_dir := Vector2(cos(ang), sin(ang))
		var local_dir := (node.to_local(origin_global + world_dir) - origin_local).normalized()
		var local_ang := atan2(local_dir.y, local_dir.x)
		angles.append(local_ang - 0.0003)
		angles.append(local_ang)
		angles.append(local_ang + 0.0003)

	var get_pt := func(orig: Vector2, dir: Vector2) -> Vector2:
		return _get_ray_polygon_intersection(orig, dir, poly)

	_draw_ray_sweep(component, node, angles, origin_local, origin_global, space_state, get_pt)

static func draw_shape_unobstructed(component: CanvasItem, shape: Shape2D) -> void:
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var r := circle.radius
		component.draw_circle(Vector2.ZERO, r, RANGE_FILL_COLOR)
		component.draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
	elif shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		var sz := rect_shape.size
		var rect := Rect2(-sz / 2.0, sz)
		component.draw_rect(rect, RANGE_FILL_COLOR, true)
		component.draw_rect(rect, RANGE_BORDER_COLOR, false, RANGE_BORDER_WIDTH)
	elif shape is CapsuleShape2D:
		var cap := shape as CapsuleShape2D
		var r := cap.radius
		var h := cap.height
		var half_h := maxf(0.0, (h / 2.0) - r)
		var pts: PackedVector2Array = []
		var segments := 16
		for i in range(segments + 1):
			var angle := PI + (PI * i / float(segments))
			pts.append(Vector2(cos(angle) * r, -half_h + sin(angle) * r))
		for i in range(segments + 1):
			var angle := (PI * i / float(segments))
			pts.append(Vector2(cos(angle) * r, half_h + sin(angle) * r))
		component.draw_colored_polygon(pts, RANGE_FILL_COLOR)
		var pts_closed := pts.duplicate()
		pts_closed.append(pts[0])
		component.draw_polyline(pts_closed, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
	elif shape is ConvexPolygonShape2D:
		var convex := shape as ConvexPolygonShape2D
		draw_polygon_unobstructed(component, convex.points)
	elif shape is ConcavePolygonShape2D:
		var concave := shape as ConcavePolygonShape2D
		var segments := concave.segments
		for i in range(0, segments.size() - 1, 2):
			component.draw_line(segments[i], segments[i + 1], RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)

static func draw_polygon_unobstructed(component: CanvasItem, poly: PackedVector2Array) -> void:
	if poly.size() < 3:
		return
	var indices := Geometry2D.triangulate_polygon(poly)
	if not indices.is_empty():
		component.draw_colored_polygon(poly, RANGE_FILL_COLOR)
	else:
		var convex_parts := Geometry2D.decompose_polygon_in_convex(poly)
		for cp in convex_parts:
			if cp.size() >= 3:
				component.draw_colored_polygon(cp, RANGE_FILL_COLOR)
	var closed := poly.duplicate()
	closed.append(poly[0])
	component.draw_polyline(closed, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
