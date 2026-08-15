class_name TargetingComponent extends Area2D

enum Strategy {FIRST, LAST, CLOSEST, STRONGEST}

@export var data: TargetingData

var _targets: Array[Node2D] = []
var _rays: Dictionary[Node2D, RayCast2D] = {}
var _active_targets: Array[Node2D] = []

func get_targets() -> Array[Node2D]:
	return _active_targets

func _ready() -> void:
	if not data:
		push_error("Missing TargetingData! %s" % get_path())
		return

	_update_collision_mask()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _update_collision_mask() -> void:
	if data:
		collision_mask = data.targeting_mask


func _physics_process(_delta: float) -> void:
	_select_target()

## Assigns up to `max_targets` nodes from `targets` to `active_targets` according to `strategy`
func _select_target() -> void:
	_targets = _targets.filter(func(t: Node2D) -> bool: return is_instance_valid(t))

	# Clean up rays for targets that are no longer valid or in _targets
	for target in _rays.keys().duplicate():
		if not is_instance_valid(target) or not _targets.has(target):
			_remove_ray_for(target)

	_active_targets.clear()

	if _targets.is_empty():
		return

	# Sort candidates according to the selected strategy
	var candidates: Array[Node2D] = _targets.duplicate()

	# Filter out candidates we can't see (blocked by walls)
	if data and not data.can_target_through_walls:
		candidates = candidates.filter(_has_line_of_sight)

	match data.strategy:
		Strategy.FIRST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var a_nav = ComponentUtil.get_component(a, NavigationComponent) as NavigationComponent
				var b_nav = ComponentUtil.get_component(b, NavigationComponent) as NavigationComponent
				var dist_a = a_nav.distance_to_goal() if a_nav else global_position.distance_squared_to(a.global_position)
				var dist_b = b_nav.distance_to_goal() if b_nav else global_position.distance_squared_to(b.global_position)
				return dist_a < dist_b
			)
		Strategy.LAST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var a_nav = ComponentUtil.get_component(a, NavigationComponent) as NavigationComponent
				var b_nav = ComponentUtil.get_component(b, NavigationComponent) as NavigationComponent
				var dist_a = a_nav.distance_to_goal() if a_nav else global_position.distance_squared_to(a.global_position)
				var dist_b = b_nav.distance_to_goal() if b_nav else global_position.distance_squared_to(b.global_position)
				return dist_a > dist_b
			)
		Strategy.CLOSEST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var dist_a = global_position.distance_squared_to(a.global_position)
				var dist_b = global_position.distance_squared_to(b.global_position)
				return dist_a < dist_b
			)
		Strategy.STRONGEST:
			candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				var a_hp = ComponentUtil.get_component(a, HealthComponent) as HealthComponent
				var b_hp = ComponentUtil.get_component(b, HealthComponent) as HealthComponent
				var hp_a = a_hp.get_health() if a_hp else 0.0
				var hp_b = b_hp.get_health() if b_hp else 0.0
				return hp_a > hp_b
			)

	var limit: int = candidates.size()
	if data.max_targets > 0:
		limit = min(data.max_targets, candidates.size())

	_active_targets = candidates.slice(0, limit)

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
