class_name NavigationComponent
extends Node

signal velocity_computed(vel: Vector2)
signal no_path_available()

@export var data: NavigationData

var movement: MovementComponent
var _exits: Array[Node2D] = []

var _actor: CharacterBody2D
var _no_path: bool = false
var _target_tower: Tower = null
var _tower_path: PackedVector2Array = PackedVector2Array()
var _tower_path_idx: int = 0
var _target_recalc_timer: float = 0.0
const TARGET_RECALC_INTERVAL: float = 0.4

var remaining_distance: float = 0.0
var _stuck_timer: float = 0.0
var _last_sample_pos: Vector2 = Vector2.ZERO
var _sample_timer: float = 0.0


func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"NavigationComponent", self)
	_actor = get_parent() as CharacterBody2D
	if !_actor:
		push_error("Must be child of a CharacterBody2D")
		return

	if not data:
		push_error("Missing NavigationData! %s" % get_path())
		return

	if not movement:
		movement = ComponentUtil.get_component(_actor, MovementComponent) as MovementComponent

	SignalBus.flow_fields_updated.connect(_on_flow_fields_updated)
	_pick_target()


func _on_flow_fields_updated() -> void:
	if data and data.targets_towers:
		_pick_target()


func set_exits(new_exits: Array[Node2D]) -> void:
	_exits = new_exits
	_pick_target()


func is_finished() -> bool:
	if _exits.is_empty():
		return false
	for exit in _exits:
		if is_instance_valid(exit) and _actor.global_position.distance_squared_to(exit.global_position) <= 256.0:
			return true
	return false


func can_reach_exit() -> bool:
	return not _no_path


func distance_to_goal() -> float:
	return remaining_distance


func get_field_id() -> String:
	var prefix: String = "ghost" if (data and (data.nav_layer & 4) != 0) else "physical"
	var size_str: String = "small"
	if data:
		if data.size == NavigationData.AgentSize.MEDIUM:
			size_str = "medium"
		elif data.size == NavigationData.AgentSize.LARGE:
			size_str = "large"

	if _exits.size() > 1 and data and data.strategy != NavigationData.NavStrategy.CLOSEST:
		var exit_idx: int = _get_target_exit_index()
		return "%s_%s_%d" % [prefix, size_str, exit_idx]

	return "%s_%s" % [prefix, size_str]


func _get_target_exit_index() -> int:
	if _exits.size() <= 1 or not data:
		return 0
	if data.strategy == NavigationData.NavStrategy.FIRST:
		return 0
	elif data.strategy == NavigationData.NavStrategy.FARTHEST:
		var max_dist: float = -1.0
		var best_idx: int = 0
		for i: int in range(_exits.size()):
			if is_instance_valid(_exits[i]):
				var d: float = _actor.global_position.distance_squared_to(_exits[i].global_position)
				if d > max_dist:
					max_dist = d
					best_idx = i
		return best_idx
	return 0


func _compute_separation_vector() -> Vector2:
	if not data or not data.enable_separation or data.separation_radius <= 0.0 or not is_instance_valid(_actor) or not _actor.is_inside_tree():
		return Vector2.ZERO

	var sep_vector: Vector2 = Vector2.ZERO
	var actor_pos: Vector2 = _actor.global_position
	var rad_sq: float = data.separation_radius * data.separation_radius
	var my_id: int = _actor.get_instance_id()

	var enemies: Array[Node] = _actor.get_tree().get_nodes_in_group("enemies")
	for node: Node in enemies:
		if is_instance_valid(node) and node is Node2D and node.get_instance_id() != my_id:
			var diff: Vector2 = actor_pos - (node as Node2D).global_position
			var d2: float = diff.length_squared()
			if d2 > 0.01 and d2 < rad_sq:
				var dist: float = sqrt(d2)
				var strength: float = 1.0 - (dist / data.separation_radius)
				sep_vector += (diff / dist) * strength

	return sep_vector


func _physics_process(delta: float) -> void:
	if is_finished():
		return

	var dir: Vector2 = Vector2.ZERO

	# 1. Tower-targeting enemies (Snipers, Bombers)
	if data and data.targets_towers:
		_target_recalc_timer += delta
		if _target_recalc_timer >= TARGET_RECALC_INTERVAL or not is_instance_valid(_target_tower) or _target_tower.is_queued_for_deletion():
			_target_recalc_timer = 0.0
			_pick_target()

		if is_instance_valid(_target_tower) and not _target_tower.is_queued_for_deletion():
			_no_path = false
			remaining_distance = _actor.global_position.distance_to(_target_tower.global_position)

			# Advance waypoints
			while _tower_path_idx < _tower_path.size() and _actor.global_position.distance_squared_to(_tower_path[_tower_path_idx]) < 256.0:
				_tower_path_idx += 1

			if _tower_path_idx < _tower_path.size():
				dir = _actor.global_position.direction_to(_tower_path[_tower_path_idx])
			else:
				dir = _actor.global_position.direction_to(_target_tower.global_position)
		else:
			# Fallback to exit flow field when no towers exist
			var field_id: String = get_field_id()
			var field: FlowField = FlowFieldManager.get_field(field_id)
			if field and field.is_reachable(_actor.global_position):
				_no_path = false
				dir = field.query(_actor.global_position)

	# 2. Standard exit-targeting enemies
	else:
		var field_id: String = get_field_id()
		var field: FlowField = FlowFieldManager.get_field(field_id)

		if field and field.is_reachable(_actor.global_position):
			_no_path = false
			dir = field.query(_actor.global_position)
		else:
			if not _no_path:
				no_path_available.emit()
				_no_path = true

		# Fallback if in unreached corner
		if dir == Vector2.ZERO and not _exits.is_empty():
			var closest_exit: Node2D = null
			var min_d_sq: float = INF
			for ex: Node2D in _exits:
				if is_instance_valid(ex):
					var d: float = _actor.global_position.distance_squared_to(ex.global_position)
					if d < min_d_sq:
						min_d_sq = d
						closest_exit = ex
			if closest_exit:
				dir = _actor.global_position.direction_to(closest_exit.global_position)

	# Soft Boid Separation (with Lateral Corridor Lane Spreading)
	if data and data.enable_separation:
		var sep: Vector2 = _compute_separation_vector()
		if sep != Vector2.ZERO:
			if dir != Vector2.ZERO:
				var flow_tangent: Vector2 = Vector2(-dir.y, dir.x)
				var lateral_sep: float = sep.dot(flow_tangent)
				var forward_sep: float = sep.dot(dir)
				var blended_sep: Vector2 = flow_tangent * lateral_sep + dir * (forward_sep * 0.25)
				dir = (dir + blended_sep * data.separation_weight).normalized()
			else:
				dir = sep.normalized()

	# Stuck / Crowd Jam Detection
	if is_instance_valid(_actor):
		_sample_timer += delta
		if _sample_timer >= 0.25:
			var dist_moved: float = _actor.global_position.distance_to(_last_sample_pos)
			_last_sample_pos = _actor.global_position
			_sample_timer = 0.0

			if dir != Vector2.ZERO and dist_moved < 1.0:
				_stuck_timer += 0.25
			else:
				_stuck_timer = maxf(0.0, _stuck_timer - 0.5)

		if _stuck_timer >= 0.8:
			var unstuck_side: float = 1.0 if (_actor.get_instance_id() % 2 == 0) else -1.0
			var perp: Vector2 = Vector2(-dir.y, dir.x) * unstuck_side
			dir = (dir * 0.7 + perp * 0.3).normalized()

	var max_speed: float = movement.get_speed() if movement else 0.0
	var intended_vel: Vector2 = dir * max_speed
	velocity_computed.emit(intended_vel)


func _pick_target() -> void:
	if not is_instance_valid(_actor) or not _actor.is_inside_tree():
		return

	if data and data.targets_towers:
		_target_tower = _find_target_tower()
		if _target_tower and is_instance_valid(_target_tower):
			_tower_path = PackedVector2Array([_target_tower.global_position])
			_tower_path_idx = 0
		else:
			_tower_path.clear()
			_tower_path_idx = 0


func _find_target_tower() -> Tower:
	if not is_instance_valid(_actor) or not _actor.is_inside_tree():
		return null

	var tree: SceneTree = _actor.get_tree()
	if not tree:
		return null

	var towers: Array[Node] = tree.get_nodes_in_group("towers")
	var candidates: Array[Tower] = []
	for node: Node in towers:
		if is_instance_valid(node) and node is Tower and not node.is_queued_for_deletion() and not (node as Tower).is_preview:
			var tower: Tower = node as Tower
			if tower.collision_layer > 0 and tower.health != null:
				candidates.append(tower)

	if candidates.is_empty():
		return null

	var best_tower: Tower = null
	var min_cost: float = INF

	for t: Tower in candidates:
		var direct_dist: float = _actor.global_position.distance_to(t.global_position)
		if direct_dist < min_cost:
			min_cost = direct_dist
			best_tower = t

	return best_tower


## Calculates the shortest path to an exit ignoring towers (using Ghost Small field)
func get_shortest_path_to_exit_ignoring_towers() -> PackedVector2Array:
	if _exits.is_empty() or not is_instance_valid(_actor):
		return PackedVector2Array()

	var field: FlowField = FlowFieldManager.get_field("ghost_small")
	if field:
		var path: PackedVector2Array = field.trace_path(_actor.global_position, 16.0, 300, _exits)
		if path.size() >= 2:
			return path

	return PackedVector2Array()


## Finds the first solid tower obstructing the given path segments
func find_first_obstructing_tower(path: PackedVector2Array) -> Tower:
	if path.size() < 2 or not is_instance_valid(_actor):
		return null

	var space_state: PhysicsDirectSpaceState2D = _actor.get_world_2d().direct_space_state
	if not space_state:
		return null

	for i: int in range(path.size() - 1):
		var p_start: Vector2 = path[i]
		var p_end: Vector2 = path[i + 1]

		var query := PhysicsRayQueryParameters2D.create(p_start, p_end, 2 | 16) # Layer 2: Solid Towers + Layer 5: Spectral Towers
		query.collide_with_bodies = true
		query.collide_with_areas = false
		var exclude_rids: Array[RID] = []

		while true:
			query.exclude = exclude_rids
			var result: Dictionary = space_state.intersect_ray(query)
			if result.is_empty():
				break
			var body = result.get("collider")
			if is_instance_valid(body) and body is Tower:
				var tower: Tower = body as Tower
				if tower.collision_layer > 0 and not tower.is_queued_for_deletion() and not tower.is_preview:
					return tower
				else:
					if result.has("rid"):
						exclude_rids.append(result.get("rid"))
					else:
						break
			else:
				if result.has("rid"):
					exclude_rids.append(result.get("rid"))
				else:
					break

	# Fallback: find closest solid tower directly on the path
	var first_tower: Tower = null
	var min_dist_from_actor: float = INF

	var towers_container: Array[Node] = _actor.get_tree().get_nodes_in_group("towers")
	for node: Node in towers_container:
		var tower: Tower = node as Tower
		if is_instance_valid(tower) and tower.collision_layer > 0 and not tower.is_queued_for_deletion() and not tower.is_preview:
			for i: int in range(path.size() - 1):
				var dist_sq: float = _dist_to_segment_squared(tower.global_position, path[i], path[i + 1])
				if dist_sq < 16.0 * 16.0:
					var dist_from_actor: float = _actor.global_position.distance_squared_to(tower.global_position)
					if dist_from_actor < min_dist_from_actor:
						min_dist_from_actor = dist_from_actor
						first_tower = tower

	return first_tower


static func _dist_to_segment_squared(p: Vector2, a: Vector2, b: Vector2) -> float:
	var l2: float = a.distance_squared_to(b)
	if l2 == 0.0:
		return p.distance_squared_to(a)
	var t: float = clampf(((p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)) / l2, 0.0, 1.0)
	var projection: Vector2 = a + t * (b - a)
	return p.distance_squared_to(projection)
