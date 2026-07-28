class_name NavigationComponent
extends Node

signal velocity_computed(vel: Vector2)
signal no_path_available()

enum NavStrategy {
	CLOSEST,		# Closest by path length
	FARTHEST,	# Farthest away by path length
	FIRST,		# First in the targets array
}

@export var strategy: NavStrategy
@export var movement: MovementComponent # Only used to grab the actors current max speed

@export var agent: NavigationAgent2D
var targets: Array[Node2D] = []

var _actor: CharacterBody2D

func _ready() -> void:
	_actor = get_parent() as CharacterBody2D
	if !_actor:
		push_error("Must be child of a CharacterBody2D")
		return

	agent.velocity_computed.connect(_on_velocity_computed)

func set_targets(new_targets: Array[Node2D]) -> void:
	targets = new_targets
	_pick_target()

func is_finished() -> bool:
	return agent.is_navigation_finished()

func _physics_process(_delta: float) -> void:
	if agent.is_navigation_finished():
		return
	
	var next_pos = agent.get_next_path_position()
	
	agent.get_current_navigation_path()
	
	if !agent.is_target_reachable():
		no_path_available.emit()
		# TODO: Instead find the first tower that blocks the previous path and attack it
		return
	
	var dir = _actor.global_position.direction_to(next_pos)
	var intended_vel = dir * movement.max_speed
	
	if agent.avoidance_enabled:
		agent.max_speed = movement.max_speed
		agent.velocity = intended_vel
	else:
		velocity_computed.emit(intended_vel)

func _on_velocity_computed(safe_vel: Vector2) -> void:
	velocity_computed.emit(safe_vel)

func _pick_target() -> void:
	if strategy == NavStrategy.FIRST:
		agent.target_position = targets[0].global_position
		return
	
	var map: RID = _actor.get_world_2d().navigation_map
	var distances = []

	for target in targets:
		var path: PackedVector2Array = NavigationServer2D.map_get_path(
			map, _actor.global_position, target.global_position, true
		)
		var length: float = _calculate_path_length(path)
		
		distances.append(length)

	match strategy:
		NavStrategy.CLOSEST:
			agent.target_position = targets[targets.find(targets.min())].global_position
		NavStrategy.FARTHEST:
			agent.target_position = targets[targets.find(targets.max())].global_position

func _calculate_path_length(path: PackedVector2Array) -> float:
	if path.size() < 2:
		return INF
	var total_len: float = 0.0
	for i in range(path.size() - 1):
		total_len += path[i].distance_to(path[i + 1])
	return total_len
