class_name NavigationComponent
extends Node

signal velocity_computed(vel: Vector2)
signal no_path_available()

@export var data: NavigationData

var movement: MovementComponent
var agent: NavigationAgent2D
var _exits: Array[Node2D] = []

var _actor: CharacterBody2D
var _no_path: bool = false
var _last_path_calc: float = 0
var _path_calc_timer: float = 0
const PATH_RECALC_TIMER: float = 1

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
	if not agent:
		agent = _actor.find_child("NavigationAgent2D", false, false) as NavigationAgent2D
		if not agent:
			agent = NavigationAgent2D.new()
			agent.name = "NavigationAgent2D"
			_actor.add_child(agent)

	if agent:
		agent.velocity_computed.connect(_on_velocity_computed)
		
		# Apply common settings shared by all enemies
		agent.navigation_layers = data.nav_layer
		agent.path_max_distance = 10
		agent.avoidance_enabled = false
		agent.neighbor_distance = 100
		agent.radius = 8
		agent.simplify_path = false
		agent.path_desired_distance = 6.0
		agent.target_desired_distance = 8.0
	
	SignalBus.navmesh_updated.connect(_pick_target)
	SignalBus.tower_placed.connect(_on_towers_changed)
	SignalBus.tower_destroyed.connect(_on_towers_changed)

func _on_towers_changed() -> void:
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
	if agent and agent.is_navigation_finished():
		return true
	return false
	
func can_reach_exit() -> bool:
	return not _no_path
	
## Returns the path distance to the current goal
func distance_to_goal() -> float:
	var stage = GameManager.current_stage
	if stage and stage.flow_field_manager and is_instance_valid(_actor):
		var field = stage.flow_field_manager.get_field(data.nav_layer if data else 1)
		var g = field.global_to_grid(_actor.global_position)
		if field.is_valid_cell(g.x, g.y):
			var idx = field.grid_to_index(g.x, g.y)
			var dist = field.integration_cost[idx]
			if dist < FlowField.BLOCKED_COST:
				return dist * field.cell_size.x

	var path: PackedVector2Array = agent.get_current_navigation_path()
	var current_index: int = agent.get_current_navigation_path_index()

	if path.is_empty() or current_index >= path.size():
		return 0.0

	var total_distance: float = _actor.global_position.distance_to(path[current_index])

	for i in range(current_index, path.size() - 1):
		total_distance += path[i].distance_to(path[i + 1])

	return total_distance

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

	if fm and not (data and data.targets_towers):
		var nav_layer = data.nav_layer if data else 1
		var is_reach = fm.is_reachable(_actor.global_position, nav_layer)
		if not is_reach:
			if not _no_path:
				no_path_available.emit()
				_no_path = true
		else:
			_no_path = false

		dir = fm.get_flow_direction(_actor.global_position, nav_layer)
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
	else:
		_path_calc_timer += delta
		if _path_calc_timer - _last_path_calc >= PATH_RECALC_TIMER:
			_last_path_calc = _path_calc_timer
			agent.target_position = agent.target_position
		
		if !agent.is_target_reachable():
			if !_no_path:
				no_path_available.emit()
				_no_path = true
		else:
			_no_path = false

		var next_pos = agent.get_next_path_position()
		dir = _actor.global_position.direction_to(next_pos)

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

		# If hard-trapped for > 1.5s (e.g. wall/tower blocked physical path), trigger attack fallback
		if _stuck_timer >= 1.5:
			if not _no_path:
				no_path_available.emit()
				_no_path = true

	var max_speed = movement.get_speed() if movement else 0.0
	var intended_vel = dir * max_speed
	
	if agent.avoidance_enabled:
		agent.max_speed = max_speed
		agent.velocity = intended_vel
	else:
		velocity_computed.emit(intended_vel)

func _on_velocity_computed(safe_vel: Vector2) -> void:
	velocity_computed.emit(safe_vel)

func _pick_target() -> void:
	_no_path = false
	agent.target_position = _actor.global_position

	if data and data.targets_towers:
		var target_tower = _find_target_tower()
		if target_tower:
			agent.target_position = target_tower.global_position
			return

	if _exits.is_empty():
		return

	if data and data.strategy == NavigationData.NavStrategy.FIRST:
		agent.target_position = _exits[0].global_position
		return
	
	var map: RID = _actor.get_world_2d().navigation_map
	var distances = []

	for target in _exits:
		var path: PackedVector2Array = NavigationServer2D.map_get_path(
			map, _actor.global_position, target.global_position, true, agent.navigation_layers
		)
		var length: float = _calculate_path_length(path)
		distances.append(length)

	if distances.is_empty():
		return

	match data.strategy if data else NavigationData.NavStrategy.CLOSEST:
		NavigationData.NavStrategy.CLOSEST:
			var min_dist: float = distances.min()
			var target_index: int = distances.find(min_dist)
			if target_index >= 0 and target_index < _exits.size():
				agent.target_position = _exits[target_index].global_position
			
		NavigationData.NavStrategy.FARTHEST:
			var max_dist: float = distances.max()
			var target_index: int = distances.find(max_dist)
			if target_index >= 0 and target_index < _exits.size():
				agent.target_position = _exits[target_index].global_position

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

	var map: RID = _actor.get_world_2d().navigation_map
	var shortest_path: PackedVector2Array = PackedVector2Array()
	var min_length: float = INF

	for exit in _exits:
		if not is_instance_valid(exit):
			continue
		var path: PackedVector2Array = NavigationServer2D.map_get_path(
			map, _actor.global_position, exit.global_position, true, 4
		)
		var length: float = _calculate_path_length(path)
		if length < min_length:
			min_length = length
			shortest_path = path

	return shortest_path



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

	# Fallback: find closest solid tower along the path
	var first_tower: Tower = null
	var min_dist_from_actor: float = INF

	var towers_container = _actor.get_tree().get_nodes_in_group("towers")
	for node in towers_container:
		var tower = node as Tower
		if is_instance_valid(tower) and tower.collision_layer > 0 and not tower.is_queued_for_deletion() and not tower.is_preview:
			for i in range(path.size() - 1):
				var dist_sq = _dist_to_segment_squared(tower.global_position, path[i], path[i + 1])
				if dist_sq < 36.0 * 36.0:
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
