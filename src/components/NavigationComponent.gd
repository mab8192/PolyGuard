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
	
	SignalBus.tower_placed.connect(_on_towers_changed)
	SignalBus.tower_destroyed.connect(_on_towers_changed)
	SignalBus.flow_fields_updated.connect(_on_flow_fields_updated)
	_pick_target()

func _on_towers_changed() -> void:
	_pick_target()

func _on_flow_fields_updated() -> void:
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
	
var remaining_distance: float = 0.0

func can_reach_exit() -> bool:
	return not _no_path
	
## Returns the path distance to the current goal
func distance_to_goal() -> float:
	return remaining_distance

var _flow_manager: FlowFieldManager = null

func _get_flow_manager() -> FlowFieldManager:
	if _flow_manager and is_instance_valid(_flow_manager):
		return _flow_manager
	var stage = GameManager.current_stage
	if stage and is_instance_valid(stage):
		_flow_manager = stage.flow_field_manager
	return _flow_manager

var _stuck_timer: float = 0.0
var _last_sample_pos: Vector2 = Vector2.ZERO
var _sample_timer: float = 0.0

func _compute_separation_vector() -> Vector2:
	if not data or not data.enable_separation or data.separation_radius <= 0.0 or not is_instance_valid(_actor):
		return Vector2.ZERO

	var fm = _get_flow_manager()
	if not fm:
		return Vector2.ZERO

	return fm.get_separation_vector(_actor.global_position, data.separation_radius, _actor.get_instance_id())

func _physics_process(delta: float) -> void:
	if is_finished():
		return

	var fm = _get_flow_manager()
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
			if fm:
				var nav_layer = data.nav_layer if data else 1
				var field = fm.get_field(nav_layer)
				var g = field.global_to_grid(_actor.global_position)
				if field.is_valid_cell(g.x, g.y) and field.integration_cost[field.grid_to_index(g.x, g.y)] < FlowField.BLOCKED_COST:
					_no_path = false
					remaining_distance = field.integration_cost[field.grid_to_index(g.x, g.y)] * field.cell_size.x
					dir = field.sample_direction(_actor.global_position)
				elif fm.walls_only_field:
					_no_path = false
					dir = fm.walls_only_field.sample_direction(_actor.global_position)

	# 2. Standard exit-targeting enemies
	elif fm:
		var nav_layer = data.nav_layer if data else 1
		var field = fm.get_field(nav_layer)
		var g = field.global_to_grid(_actor.global_position)
		var has_valid_cost = field.is_valid_cell(g.x, g.y) and field.integration_cost[field.grid_to_index(g.x, g.y)] < FlowField.BLOCKED_COST

		if has_valid_cost:
			_no_path = false
			remaining_distance = field.integration_cost[field.grid_to_index(g.x, g.y)] * field.cell_size.x
			dir = field.sample_direction(_actor.global_position)
		else:
			var is_reach = fm.is_reachable(_actor.global_position, nav_layer)
			if not is_reach:
				if not _no_path:
					no_path_available.emit()
					_no_path = true
				# When blocked by barricades/towers, route along walls_only_field directly to the blocking barricade/tower
				if fm.walls_only_field:
					var wg = fm.walls_only_field.global_to_grid(_actor.global_position)
					if fm.walls_only_field.is_valid_cell(wg.x, wg.y):
						remaining_distance = fm.walls_only_field.integration_cost[fm.walls_only_field.grid_to_index(wg.x, wg.y)] * fm.walls_only_field.cell_size.x
					dir = fm.walls_only_field.sample_direction(_actor.global_position)
			else:
				_no_path = false
				dir = field.sample_direction(_actor.global_position)

		if dir == Vector2.ZERO and not _exits.is_empty():
			var closest_exit: Node2D = null
			var min_d_sq: float = INF
			for ex in _exits:
				if is_instance_valid(ex):
					var d = _actor.global_position.distance_squared_to(ex.global_position)
					if d < min_d_sq:
						min_d_sq = d
						closest_exit = ex
			if closest_exit:
				dir = _actor.global_position.direction_to(closest_exit.global_position)

	if data and data.enable_separation:
		var sep = _compute_separation_vector()
		if sep != Vector2.ZERO:
			dir = (dir + sep * data.separation_weight).normalized()

	# Dynamic Stuck / Crowd Jam Detection
	if is_instance_valid(_actor):
		_sample_timer += delta
		if _sample_timer >= 0.2:
			var dist_moved = _actor.global_position.distance_to(_last_sample_pos)
			_last_sample_pos = _actor.global_position
			_sample_timer = 0.0

			if dir != Vector2.ZERO and dist_moved < 3.0:
				_stuck_timer += 0.2
			else:
				_stuck_timer = maxf(0.0, _stuck_timer - 0.4)

		# If jammed in an arch against another unit, apply lateral unstuck torque
		if _stuck_timer >= 0.3:
			var unstuck_side = 1.0 if (_actor.get_instance_id() % 2 == 0) else -1.0
			var perp = Vector2(-dir.y, dir.x) * unstuck_side
			dir = (dir * 0.4 + perp * 0.8).normalized()

	var max_speed = movement.get_speed() if movement else 0.0
	var intended_vel = dir * max_speed
	velocity_computed.emit(intended_vel)

func _pick_target() -> void:
	if not is_instance_valid(_actor) or not _actor.is_inside_tree():
		return

	if data and data.targets_towers:
		_target_tower = _find_target_tower()
		if _target_tower and is_instance_valid(_target_tower):
			var fm = _get_flow_manager()
			if fm:
				_tower_path = fm.find_grid_path(_actor.global_position, _target_tower.global_position)
				_tower_path_idx = 0
		else:
			_tower_path.clear()
			_tower_path_idx = 0

func _find_target_tower() -> Tower:
	if not is_instance_valid(_actor) or not _actor.is_inside_tree():
		return null

	var tree = _actor.get_tree()
	if not tree:
		return null

	var towers = tree.get_nodes_in_group("towers")
	var candidates: Array[Tower] = []
	for node in towers:
		if is_instance_valid(node) and node is Tower and not node.is_queued_for_deletion() and not node.is_preview:
			if node.collision_layer > 0 and node.health != null:
				candidates.append(node)

	if candidates.is_empty():
		return null

	var best_tower: Tower = null
	var min_dist_sq: float = INF
	for t in candidates:
		var d_sq = _actor.global_position.distance_squared_to(t.global_position)
		if d_sq < min_dist_sq:
			min_dist_sq = d_sq
			best_tower = t

	return best_tower

func _calculate_path_length(path: PackedVector2Array) -> float:
	if path.size() < 2:
		return INF
	var total_len: float = 0.0
	for i in range(path.size() - 1):
		total_len += path[i].distance_to(path[i + 1])
	return total_len

## Calculates the shortest path to an exit ignoring towers (using nav layer 4 for walls-only)
func get_shortest_path_to_exit_ignoring_towers() -> PackedVector2Array:
	if _exits.is_empty() or not is_instance_valid(_actor):
		return PackedVector2Array()

	var stage = GameManager.current_stage
	if stage and stage.flow_field_manager and stage.flow_field_manager.walls_only_field:
		var path = stage.flow_field_manager.walls_only_field.trace_path(_actor.global_position, 16.0, 300, _exits)
		if path.size() >= 2:
			return path

	return PackedVector2Array()



## Finds the first solid tower obstructing the given path segments
func find_first_obstructing_tower(path: PackedVector2Array) -> Tower:
	if path.size() < 2 or not is_instance_valid(_actor):
		return null

	var space_state = _actor.get_world_2d().direct_space_state
	if not space_state:
		return null

	# Trace raycasts along path segments to find first obstructing solid tower
	for i in range(path.size() - 1):
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
				var tower = body as Tower
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

	var towers_container = _actor.get_tree().get_nodes_in_group("towers")
	for node in towers_container:
		var tower = node as Tower
		if is_instance_valid(tower) and tower.collision_layer > 0 and not tower.is_queued_for_deletion() and not tower.is_preview:
			for i in range(path.size() - 1):
				var dist_sq = _dist_to_segment_squared(tower.global_position, path[i], path[i + 1])
				if dist_sq < 16.0 * 16.0:
					var dist_from_actor = _actor.global_position.distance_squared_to(tower.global_position)
					if dist_from_actor < min_dist_from_actor:
						min_dist_from_actor = dist_from_actor
						first_tower = tower

	return first_tower


static func _dist_to_segment_squared(p: Vector2, a: Vector2, b: Vector2) -> float:
	var l2 = a.distance_squared_to(b)
	if l2 == 0.0:
		return p.distance_squared_to(a)
	var t = clampf(((p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)) / l2, 0.0, 1.0)
	var projection = a + t * (b - a)
	return p.distance_squared_to(projection)
