class_name TargetingComponent extends Area2D

enum Strategy {FIRST, LAST, CLOSEST, STRONGEST}

@export var data: TargetingData

var _targets: Array[Enemy] = []
var _rays: Dictionary[Enemy, RayCast2D] = {}
var _active_targets: Array[Enemy] = []

func get_targets() -> Array[Enemy]:
	return _active_targets

func _ready() -> void:
	if not data:
		push_error("Missing component data! %s" % get_path())
		return

	_update_collision_mask()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _update_collision_mask() -> void:
	if data:
		collision_mask = data.targeting_mask


func _physics_process(_delta: float) -> void:
	_select_target()

## Assigns up to `max_targets` enemies from `targets` to `active_targets` according to `strategy`
func _select_target() -> void:
	_targets = _targets.filter(func(t: Enemy) -> bool: return is_instance_valid(t))

	# Clean up rays for enemies that are no longer valid or in _targets
	for enemy in _rays.keys().duplicate():
		if not is_instance_valid(enemy) or not _targets.has(enemy):
			_remove_ray_for(enemy)

	_active_targets.clear()

	if _targets.is_empty():
		return

	# Sort candidates according to the selected strategy
	var candidates: Array[Enemy] = _targets.duplicate()

	# Filter out candidates we can't see (blocked by walls)
	if data and not data.can_target_through_walls:
		candidates = candidates.filter(_has_line_of_sight)

	match data.strategy:
		Strategy.FIRST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var dist_a = a.nav.distance_to_goal() if a.nav else INF
				var dist_b = b.nav.distance_to_goal() if b.nav else INF
				return dist_a < dist_b
			)
		Strategy.LAST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var dist_a = a.nav.distance_to_goal() if a.nav else -INF
				var dist_b = b.nav.distance_to_goal() if b.nav else -INF
				return dist_a > dist_b
			)
		Strategy.CLOSEST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var dist_a = global_position.distance_squared_to(a.global_position)
				var dist_b = global_position.distance_squared_to(b.global_position)
				return dist_a < dist_b
			)
		Strategy.STRONGEST:
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
				var hp_a = a.health.get_health() if a.health else 0.0
				var hp_b = b.health.get_health() if b.health else 0.0
				return hp_a > hp_b
			)

	var limit: int = candidates.size()
	if data.max_targets > 0:
		limit = min(data.max_targets, candidates.size())

	_active_targets = candidates.slice(0, limit)

func _has_line_of_sight(enemy: Enemy) -> bool:
	if not is_instance_valid(enemy):
		return false
	var ray: RayCast2D = _rays.get(enemy)
	if not ray or not is_instance_valid(ray):
		_create_ray_for(enemy)
		ray = _rays.get(enemy)
	if not ray:
		return true

	ray.target_position = ray.to_local(enemy.global_position)
	ray.force_raycast_update()
	return not ray.is_colliding()

func _create_ray_for(enemy: Enemy) -> void:
	if _rays.has(enemy) or not is_instance_valid(enemy):
		return
	var ray := RayCast2D.new()
	ray.collision_mask = 1 # Layer 1: Walls / Environment
	ray.enabled = true
	if get_parent() is CollisionObject2D:
		ray.add_exception(get_parent())
	add_child(ray)
	_rays[enemy] = ray

func _remove_ray_for(enemy: Enemy) -> void:
	if _rays.has(enemy):
		var ray = _rays[enemy]
		if is_instance_valid(ray):
			ray.queue_free()
		_rays.erase(enemy)

func _on_body_entered(body: Node2D) -> void:
	var enemy = body as Enemy
	if enemy and not _targets.has(enemy):
		_targets.append(enemy)
		if not data.can_target_through_walls:
			_create_ray_for(enemy)

func _on_body_exited(body: Node2D) -> void:
	if body is Enemy:
		var enemy = body as Enemy
		_targets.erase(enemy)
		_active_targets.erase(enemy)
		_remove_ray_for(enemy)
