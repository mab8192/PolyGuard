class_name TargetingComponent extends Area2D

@export var data: TargetingData:
	set(val):
		data = val
		if data:
			collision_mask = data.targeting_mask

const RANGE_BORDER_COLOR: Color = Color(0.0, 0.96, 0.83, 0.95)
const RANGE_FILL_COLOR: Color = Color(0.0, 0.96, 0.83, 0.12)
const RANGE_BORDER_WIDTH: float = 2.5

const BLOCKED_RANGE_BORDER_COLOR: Color = Color(1.0, 0.25, 0.25, 0.85)
const BLOCKED_RANGE_FILL_COLOR: Color = Color(1.0, 0.18, 0.18, 0.15)

var is_range_visible: bool = false:
	set(value):
		if is_range_visible != value:
			is_range_visible = value
			_last_range_pos = Vector2.INF
			set_process(value)
			queue_redraw()

var _last_range_pos: Vector2 = Vector2.INF
var _last_range_rot: float = 0.0

var _targets: Array[Node2D] = []
var _active_targets: Array[Node2D] = []
var _sort_scratch: Array[Node2D] = []
var _target_update_timer: float = 0.0
const TARGET_UPDATE_INTERVAL: float = 0.05 ## 20 Hz targeting scans

## Replaces the zero-width wall raycast when set (projectile attacks sweep their real hitbox instead)
var line_of_sight_check: Callable = Callable()

func set_range_visible(vis: bool) -> void:
	is_range_visible = vis

func get_targets() -> Array[Node2D]:
	return _active_targets

func _ready() -> void:
	z_index = 12
	z_as_relative = false

	if not data:
		push_error("Missing TargetingData! %s" % get_path())

	if get_parent():
		get_parent().set_meta(&"TargetingComponent", self)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if data:
		collision_mask = data.targeting_mask

	set_process(is_range_visible)

func _process(_delta: float) -> void:
	if global_position != _last_range_pos or global_rotation != _last_range_rot:
		_last_range_pos = global_position
		_last_range_rot = global_rotation
		queue_redraw()

func _physics_process(delta: float) -> void:
	if _targets.is_empty():
		if not _active_targets.is_empty():
			_active_targets.clear()
		return

	_target_update_timer += delta
	if _target_update_timer >= TARGET_UPDATE_INTERVAL:
		_target_update_timer = 0.0
		_update_targets()

func _compact_targets() -> void:
	var write_idx: int = 0
	for i in range(_targets.size()):
		var node := _targets[i]
		if is_instance_valid(node):
			if write_idx != i:
				_targets[write_idx] = node
			write_idx += 1
	_targets.resize(write_idx)

func _is_valid_candidate(node: Node2D) -> bool:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return false
	if node is Enemy and (node as Enemy).health and (node as Enemy).health.get_health() <= 0.0:
		return false
	return true

func _update_targets() -> void:
	_compact_targets()

	if _targets.is_empty():
		_active_targets.clear()
		return

	var max_allowed: int = data.max_targets if (data and data.max_targets > 0) else 1
	var need_los: bool = data != null and not data.can_target_through_walls

	if data and data.lock_on and not _active_targets.is_empty():
		var write_idx: int = 0
		for t in _active_targets:
			if write_idx >= max_allowed:
				break
			if _is_valid_candidate(t) and _targets.has(t) and (not need_los or _has_line_of_sight(t)):
				_active_targets[write_idx] = t
				write_idx += 1
		_active_targets.resize(write_idx)
		if _active_targets.size() >= max_allowed:
			return
		_fill_active_targets(max_allowed, need_los, true)
		return

	_fill_active_targets(max_allowed, need_los, false)

func _fill_active_targets(max_allowed: int, need_los: bool, keep_retained: bool) -> void:
	_sort_scratch.clear()
	for t in _targets:
		if _is_valid_candidate(t):
			_sort_scratch.append(t)

	if max_allowed == 1 and not keep_retained:
		var best := _find_best_candidate(_sort_scratch)
		if best and (not need_los or _has_line_of_sight(best)):
			_active_targets.clear()
			_active_targets.append(best)
			return

	_sort_candidates(_sort_scratch)

	if not keep_retained:
		_active_targets.clear()

	for c in _sort_scratch:
		if _active_targets.size() >= max_allowed:
			break
		if keep_retained and _active_targets.has(c):
			continue
		if need_los and not _has_line_of_sight(c):
			continue
		_active_targets.append(c)

func _get_strategy_comparator() -> Callable:
	if not data:
		return Callable()
	match data.strategy:
		TargetingData.Strategy.FIRST:
			return _cmp_first
		TargetingData.Strategy.LAST:
			return _cmp_last
		TargetingData.Strategy.CLOSEST:
			return _cmp_closest
		TargetingData.Strategy.FARTHEST:
			return _cmp_farthest
		TargetingData.Strategy.STRONGEST:
			return _cmp_strongest
		TargetingData.Strategy.WEAKEST:
			return _cmp_weakest
	return Callable()

func _sort_candidates(candidates: Array[Node2D]) -> void:
	if candidates.size() < 2:
		return
	var comparator := _get_strategy_comparator()
	if comparator.is_valid():
		candidates.sort_custom(comparator)

## Same pick as the first element after _sort_candidates, in a single pass
func _find_best_candidate(candidates: Array[Node2D]) -> Node2D:
	if candidates.is_empty():
		return null
	var best: Node2D = candidates[0]
	var comparator := _get_strategy_comparator()
	if comparator.is_valid():
		for i in range(1, candidates.size()):
			if comparator.call(candidates[i], best):
				best = candidates[i]
	return best

func _cmp_first(a: Node2D, b: Node2D) -> bool:
	var a_e := a as Enemy
	var b_e := b as Enemy
	if a_e and b_e and not is_equal_approx(a_e.nav.remaining_distance, b_e.nav.remaining_distance):
		return a_e.nav.remaining_distance < b_e.nav.remaining_distance
	return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)

func _cmp_last(a: Node2D, b: Node2D) -> bool:
	var a_e := a as Enemy
	var b_e := b as Enemy
	if a_e and b_e and not is_equal_approx(a_e.nav.remaining_distance, b_e.nav.remaining_distance):
		return a_e.nav.remaining_distance > b_e.nav.remaining_distance
	return global_position.distance_squared_to(a.global_position) > global_position.distance_squared_to(b.global_position)

func _cmp_closest(a: Node2D, b: Node2D) -> bool:
	var d_a := global_position.distance_squared_to(a.global_position)
	var d_b := global_position.distance_squared_to(b.global_position)
	if not is_equal_approx(d_a, d_b):
		return d_a < d_b
	var a_e := a as Enemy
	var b_e := b as Enemy
	if a_e and b_e:
		return a_e.nav.remaining_distance < b_e.nav.remaining_distance
	return false

func _cmp_farthest(a: Node2D, b: Node2D) -> bool:
	var d_a := global_position.distance_squared_to(a.global_position)
	var d_b := global_position.distance_squared_to(b.global_position)
	if not is_equal_approx(d_a, d_b):
		return d_a > d_b
	var a_e := a as Enemy
	var b_e := b as Enemy
	if a_e and b_e:
		return a_e.nav.remaining_distance < b_e.nav.remaining_distance
	return false

func _cmp_strongest(a: Node2D, b: Node2D) -> bool:
	var a_e := a as Enemy
	var b_e := b as Enemy
	if a_e and b_e:
		var a_hp := a_e.health.get_health()
		var b_hp := b_e.health.get_health()
		if not is_equal_approx(a_hp, b_hp):
			return a_hp > b_hp
		if not is_equal_approx(a_e.nav.remaining_distance, b_e.nav.remaining_distance):
			return a_e.nav.remaining_distance < b_e.nav.remaining_distance
	return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)

func _cmp_weakest(a: Node2D, b: Node2D) -> bool:
	var a_e := a as Enemy
	var b_e := b as Enemy
	if a_e and b_e:
		var a_hp := a_e.health.get_health()
		var b_hp := b_e.health.get_health()
		if not is_equal_approx(a_hp, b_hp):
			return a_hp < b_hp
		if not is_equal_approx(a_e.nav.remaining_distance, b_e.nav.remaining_distance):
			return a_e.nav.remaining_distance < b_e.nav.remaining_distance
	return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)

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

func get_targeting_origin_global() -> Vector2:
	return RangeVisualizer.get_targeting_origin_global(self)

func _has_line_of_sight(target: Node2D) -> bool:
	if not is_instance_valid(target) or not is_inside_tree():
		return false
	if line_of_sight_check.is_valid():
		return line_of_sight_check.call(target)
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not space_state:
		return true

	var from_pos: Vector2 = get_targeting_origin_global()
	var to_pos: Vector2 = target.global_position

	var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos, 1) # Layer 1: Level Colliders / Walls
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var parent_node = get_parent()
	if parent_node is CollisionObject2D:
		query.exclude = [parent_node.get_rid()]

	var hit: Dictionary = space_state.intersect_ray(query)
	return hit.is_empty()

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(body) and body != owner and not _targets.has(body):
		_targets.append(body)

func _on_body_exited(body: Node2D) -> void:
	if is_instance_valid(body) and _targets.has(body):
		_targets.erase(body)
		_active_targets.erase(body)

func _draw() -> void:
	if not is_range_visible:
		return
	var can_shoot_through := data != null and data.can_target_through_walls
	RangeVisualizer.draw_range(self, can_shoot_through)
