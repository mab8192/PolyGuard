class_name NavigationComponent
extends Node

signal velocity_computed(vel: Vector2)
signal no_path_available()

enum NavStrategy {
	CLOSEST,		# Closest by path length
	FARTHEST,	# Farthest away by path length
	FIRST,		# First in the targets array
}

@export var data: NavigationData

var movement: MovementComponent
var agent: NavigationAgent2D
var targets: Array[Node2D] = []

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

	if agent:
		agent.velocity_computed.connect(_on_velocity_computed)
		
		# Apply common settings shared by all enemies
		agent.navigation_layers = data.nav_layer
		agent.path_max_distance = 10
		agent.avoidance_enabled = true
		agent.simplify_path = false
		agent.path_desired_distance = 6.0
		agent.target_desired_distance = 8.0

func set_targets(new_targets: Array[Node2D]) -> void:
	targets = new_targets
	_pick_target()

func is_finished() -> bool:
	return agent.is_navigation_finished()
	
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
	
	var next_pos = agent.get_next_path_position()
	
	if !agent.is_target_reachable():
		if !_no_path:
			no_path_available.emit()
			_no_path = true
		return
	
	_no_path = false
	
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
	if targets.is_empty():
		return

	if data.strategy == NavStrategy.FIRST:
		agent.target_position = targets[0].global_position
		return
	
	var map: RID = _actor.get_world_2d().navigation_map
	var distances = []

	for target in targets:
		var path: PackedVector2Array = NavigationServer2D.map_get_path(
			map, _actor.global_position, target.global_position, true, agent.navigation_layers
		)
		var length: float = _calculate_path_length(path)
		
		distances.append(length)

	if distances.is_empty():
		return

	match data.strategy:
		NavStrategy.CLOSEST:
			# Find the lowest number in the distances array
			var min_dist: float = distances.min()
			# Find which index that number belongs to
			var target_index: int = distances.find(min_dist)
			# Grab the corresponding target
			agent.target_position = targets[target_index].global_position
			
		NavStrategy.FARTHEST:
			# Do the exact same thing, but for the maximum distance
			var max_dist: float = distances.max()
			var target_index: int = distances.find(max_dist)
			agent.target_position = targets[target_index].global_position

func _calculate_path_length(path: PackedVector2Array) -> float:
	if path.size() < 2:
		return INF
	var total_len: float = 0.0
	for i in range(path.size() - 1):
		total_len += path[i].distance_to(path[i + 1])
	return total_len
