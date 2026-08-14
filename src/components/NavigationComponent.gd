class_name NavigationComponent
extends Node

signal velocity_computed(vel: Vector2)
signal no_path_available()

enum NavStrategy {
	CLOSEST, # Closest by path length
	FARTHEST, # Farthest away by path length
	FIRST, # First in the _exits array
}

@export var data: NavigationData

var movement: MovementComponent
var agent: NavigationAgent2D
var _exits: Array[Node2D] = []

var _actor: CharacterBody2D
var _no_path: bool = false

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
		agent.avoidance_enabled = true
		agent.neighbor_distance = 100
		agent.radius = 8
		agent.simplify_path = false
		agent.path_desired_distance = 6.0
		agent.target_desired_distance = 8.0
	
	SignalBus.navmesh_updated.connect(_pick_target)

func set_exits(new_exits: Array[Node2D]) -> void:
	_exits = new_exits
	_pick_target()

func is_finished() -> bool:
	return agent.is_navigation_finished()
	
func can_reach_exit() -> bool:
	return not _no_path
	
## Returns the path distance to the current goal
func distance_to_goal() -> float:
	var path: PackedVector2Array = agent.get_current_navigation_path()
	var current_index: int = agent.get_current_navigation_path_index()

	if path.is_empty() or current_index >= path.size():
		return 0.0

	var total_distance: float = _actor.global_position.distance_to(path[current_index])

	for i in range(current_index, path.size() - 1):
		total_distance += path[i].distance_to(path[i + 1])

	return total_distance

func _physics_process(_delta: float) -> void:
	if agent.is_navigation_finished():
		return
	
	if !agent.is_target_reachable():
		if !_no_path:
			no_path_available.emit()
			_no_path = true
	else:
		_no_path = false

	var next_pos = agent.get_next_path_position()
	var dir = _actor.global_position.direction_to(next_pos)
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
	if _exits.is_empty():
		return

	if data and data.strategy == NavStrategy.FIRST:
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

	match data.strategy if data else NavStrategy.CLOSEST:
		NavStrategy.CLOSEST:
			var min_dist: float = distances.min()
			var target_index: int = distances.find(min_dist)
			if target_index >= 0 and target_index < _exits.size():
				agent.target_position = _exits[target_index].global_position
			
		NavStrategy.FARTHEST:
			var max_dist: float = distances.max()
			var target_index: int = distances.find(max_dist)
			if target_index >= 0 and target_index < _exits.size():
				agent.target_position = _exits[target_index].global_position

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

	var map: RID = _actor.get_world_2d().navigation_map
	var shortest_path: PackedVector2Array = PackedVector2Array()
	var min_length: float = INF

	for exit in _exits:
		if not is_instance_valid(exit):
			continue
		# Layer 4 in NavMeshGenerator is navigation layer that ignores towers and only respects stage walls
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

		var query := PhysicsRayQueryParameters2D.create(p_start, p_end, 2) # Layer 2: Towers
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
				if tower.is_solid and not tower.is_queued_for_deletion() and not tower.is_preview:
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
		if is_instance_valid(tower) and tower.is_solid and not tower.is_queued_for_deletion() and not tower.is_preview:
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
