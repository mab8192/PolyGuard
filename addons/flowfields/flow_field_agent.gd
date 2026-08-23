class_name FlowFieldAgent
extends CharacterBody2D

## ============================================================================
## FlowFieldAgent
## ----------------------------------------------------------------------------
## Drop-in example of a unit that follows a shared FlowField registered with
## FlowFieldManager (see flow_field_manager.gd). Steering is a simple
## seek-with-acceleration model; swap _get_steering_velocity() out for your
## own flocking/avoidance if you need it.
## ============================================================================

@export var field_id: String = "default"
@export var move_speed: float = 220.0
@export var acceleration: float = 900.0
@export var rotate_to_face_velocity: bool = false
## Distance (in pixels) from a goal cell's center within which the agent is
## considered "arrived" and will decelerate to a stop instead of orbiting it.
@export var arrival_radius: float = 8.0

var _field: FlowField


func _ready() -> void:
	var manager: FlowFieldManager = get_node_or_null("/root/FlowFieldManager") as FlowFieldManager
	if manager != null:
		_field = manager.get_field(field_id)
	if _field == null:
		push_warning("FlowFieldAgent: field '%s' not found. Did you register it with FlowFieldManager?" % field_id)


## Call this if the agent is spawned before the field exists, or the field id
## changes at runtime.
func set_field(field: FlowField) -> void:
	_field = field


func _physics_process(delta: float) -> void:
	if _field == null or _field.is_baking():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var target_velocity: Vector2 = _get_steering_velocity()
	velocity = velocity.move_toward(target_velocity, acceleration * delta)

	if rotate_to_face_velocity and velocity.length_squared() > 4.0:
		rotation = velocity.angle()

	move_and_slide()


func _get_steering_velocity() -> Vector2:
	if _field.has_reached_goal_world(global_position):
		return Vector2.ZERO

	var flow_dir: Vector2 = _field.sample_flow_world(global_position, true)
	if flow_dir == Vector2.ZERO:
		return Vector2.ZERO

	# Slow down gracefully as the agent nears its goal cell rather than
	# stopping abruptly, using the integration value as a rough distance proxy.
	var dist_units: float = float(_field.get_integration_at_world(global_position)) / 10.0
	var slow_distance_cells: float = arrival_radius / _field.cell_size
	var speed_scale: float = clampf(dist_units / maxf(slow_distance_cells, 0.001), 0.0, 1.0)

	return flow_dir * move_speed * speed_scale
