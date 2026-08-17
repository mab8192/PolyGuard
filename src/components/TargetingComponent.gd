class_name TargetingComponent extends Area2D

@export var data: TargetingData:
	set(val):
		data = val
		if data:
			collision_mask = data.targeting_mask

const RANGE_BORDER_COLOR: Color = Color(0.0, 0.96, 0.83, 0.95)
const RANGE_FILL_COLOR: Color = Color(0.0, 0.96, 0.83, 0.12)
const RANGE_BORDER_WIDTH: float = 2.5

var is_range_visible: bool = false:
	set(value):
		if is_range_visible != value:
			is_range_visible = value
			queue_redraw()

var _targets: Array[Node2D] = []
var _rays: Dictionary[Node2D, RayCast2D] = {}
var _active_targets: Array[Node2D] = []

func set_range_visible(vis: bool) -> void:
	is_range_visible = vis

func get_targets() -> Array[Node2D]:
	return _active_targets

func _ready() -> void:
	if not data:
		push_error("Missing TargetingData! %s" % get_path())

	if get_parent():
		get_parent().set_meta(&"TargetingComponent", self)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if data:
		collision_mask = data.targeting_mask

func _process(_delta: float) -> void:
	_update_targets()

func _update_targets() -> void:
	_targets = _targets.filter(func(node): return is_instance_valid(node))
	
	for target in _rays.keys():
		if not is_instance_valid(target):
			var ray = _rays[target]
			if is_instance_valid(ray):
				ray.queue_free()
			_rays.erase(target)

	if _targets.is_empty():
		return

	# Sort candidates according to the selected strategy
	var candidates: Array[Node2D] = _targets.duplicate()

	# Filter out candidates we can't see (blocked by walls)
	if data and not data.can_target_through_walls:
		candidates = candidates.filter(_has_line_of_sight)

	match data.strategy:
		TargetingData.Strategy.FIRST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var a_nav = ComponentUtil.get_component(a, NavigationComponent) as NavigationComponent
				var b_nav = ComponentUtil.get_component(b, NavigationComponent) as NavigationComponent
				var dist_a = a_nav.distance_to_goal() if a_nav else global_position.distance_squared_to(a.global_position)
				var dist_b = b_nav.distance_to_goal() if b_nav else global_position.distance_squared_to(b.global_position)
				return dist_a < dist_b
			)
		TargetingData.Strategy.LAST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var a_nav = ComponentUtil.get_component(a, NavigationComponent) as NavigationComponent
				var b_nav = ComponentUtil.get_component(b, NavigationComponent) as NavigationComponent
				var dist_a = a_nav.distance_to_goal() if a_nav else global_position.distance_squared_to(a.global_position)
				var dist_b = b_nav.distance_to_goal() if b_nav else global_position.distance_squared_to(b.global_position)
				return dist_a > dist_b
			)
		TargetingData.Strategy.CLOSEST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var dist_a = global_position.distance_squared_to(a.global_position)
				var dist_b = global_position.distance_squared_to(b.global_position)
				return dist_a < dist_b
			)
		TargetingData.Strategy.FARTHEST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var dist_a = global_position.distance_squared_to(a.global_position)
				var dist_b = global_position.distance_squared_to(b.global_position)
				return dist_a > dist_b
			)
		TargetingData.Strategy.STRONGEST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var a_hp = ComponentUtil.get_component(a, HealthComponent) as HealthComponent
				var b_hp = ComponentUtil.get_component(b, HealthComponent) as HealthComponent
				var hp_a = a_hp.get_health() if a_hp else 0.0
				var hp_b = b_hp.get_health() if b_hp else 0.0
				return hp_a > hp_b
			)
		TargetingData.Strategy.WEAKEST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var a_hp = ComponentUtil.get_component(a, HealthComponent) as HealthComponent
				var b_hp = ComponentUtil.get_component(b, HealthComponent) as HealthComponent
				var hp_a = a_hp.get_health() if a_hp else 0.0
				var hp_b = b_hp.get_health() if b_hp else 0.0
				return hp_a < hp_b
			)

	var limit: int = candidates.size()
	if data.max_targets > 0:
		limit = min(data.max_targets, candidates.size())

	_active_targets = candidates.slice(0, limit)

func get_strategy() -> TargetingData.Strategy:
	return data.strategy if data else TargetingData.Strategy.FIRST

func set_strategy(strat: TargetingData.Strategy) -> void:
	if data:
		data.strategy = strat
		_update_targets()

func cycle_strategy(forward: bool = true) -> TargetingData.Strategy:
	if not data:
		return TargetingData.Strategy.FIRST
	var count = TargetingData.Strategy.size()
	var next_val = (int(data.strategy) + (1 if forward else -1) + count) % count
	data.strategy = next_val as TargetingData.Strategy
	_update_targets()
	return data.strategy

func get_strategy_name() -> String:
	match get_strategy():
		TargetingData.Strategy.FIRST: return "FIRST"
		TargetingData.Strategy.LAST: return "LAST"
		TargetingData.Strategy.CLOSEST: return "CLOSEST"
		TargetingData.Strategy.FARTHEST: return "FARTHEST"
		TargetingData.Strategy.STRONGEST: return "STRONGEST"
		TargetingData.Strategy.WEAKEST: return "WEAKEST"
		_: return "FIRST"

func get_strategy_description() -> String:
	match get_strategy():
		TargetingData.Strategy.FIRST: return "Targets enemy nearest to exit"
		TargetingData.Strategy.LAST: return "Targets enemy farthest from exit"
		TargetingData.Strategy.CLOSEST: return "Targets enemy closest to tower"
		TargetingData.Strategy.FARTHEST: return "Targets enemy farthest from tower"
		TargetingData.Strategy.STRONGEST: return "Targets enemy with highest HP"
		TargetingData.Strategy.WEAKEST: return "Targets enemy with lowest HP"
		_: return ""

func _has_line_of_sight(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	var ray: RayCast2D = _rays.get(target)
	if not ray or not is_instance_valid(ray):
		_create_ray_for(target)
		ray = _rays.get(target)
	if not ray:
		return true

	ray.target_position = ray.to_local(target.global_position)
	ray.force_raycast_update()
	return not ray.is_colliding()

func _create_ray_for(target: Node2D) -> void:
	if _rays.has(target) or not is_instance_valid(target):
		return
	var ray := RayCast2D.new()
	ray.collision_mask = 1 # Layer 1: Walls / Environment
	ray.enabled = true
	if get_parent() is CollisionObject2D:
		ray.add_exception(get_parent())
	add_child(ray)
	_rays[target] = ray

func _remove_ray_for(target: Node2D) -> void:
	if _rays.has(target):
		var ray = _rays[target]
		if is_instance_valid(ray):
			ray.queue_free()
		_rays.erase(target)

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(body) and body != owner and not _targets.has(body):
		_targets.append(body)
		if not data.can_target_through_walls:
			_create_ray_for(body)

func _on_body_exited(body: Node2D) -> void:
	if is_instance_valid(body) and _targets.has(body):
		_targets.erase(body)
		_active_targets.erase(body)
		_remove_ray_for(body)

func _draw() -> void:
	if not is_range_visible:
		return

	for child in get_children():
		if child is CollisionShape2D:
			var col_shape := child as CollisionShape2D
			if col_shape.disabled or not col_shape.shape:
				continue
			draw_set_transform(col_shape.position, col_shape.rotation, col_shape.scale)
			_draw_shape(col_shape.shape)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif child is CollisionPolygon2D:
			var col_poly := child as CollisionPolygon2D
			if col_poly.disabled or col_poly.polygon.is_empty():
				continue
			draw_set_transform(col_poly.position, col_poly.rotation, col_poly.scale)
			_draw_polygon(col_poly.polygon)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_shape(shape: Shape2D) -> void:
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var r := circle.radius
		draw_circle(Vector2.ZERO, r, RANGE_FILL_COLOR)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
	elif shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		var sz := rect_shape.size
		var rect := Rect2(-sz / 2.0, sz)
		draw_rect(rect, RANGE_FILL_COLOR, true)
		draw_rect(rect, RANGE_BORDER_COLOR, false, RANGE_BORDER_WIDTH)
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
		draw_colored_polygon(pts, RANGE_FILL_COLOR)
		var pts_closed := pts.duplicate()
		pts_closed.append(pts[0])
		draw_polyline(pts_closed, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
	elif shape is ConvexPolygonShape2D:
		var convex := shape as ConvexPolygonShape2D
		_draw_polygon(convex.points)
	elif shape is ConcavePolygonShape2D:
		var concave := shape as ConcavePolygonShape2D
		var segments := concave.segments
		for i in range(0, segments.size() - 1, 2):
			draw_line(segments[i], segments[i + 1], RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)

func _draw_polygon(poly: PackedVector2Array) -> void:
	if poly.size() < 3:
		return
	draw_colored_polygon(poly, RANGE_FILL_COLOR)
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, RANGE_BORDER_COLOR, RANGE_BORDER_WIDTH, true)
