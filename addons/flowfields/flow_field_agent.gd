class_name FlowFieldAgent
extends CharacterBody2D

## ============================================================================
## FlowFieldAgent
## ----------------------------------------------------------------------------
## Drop-in example of a unit that follows a shared FlowField registered with
## FlowFieldManager (see flow_field_manager.gd). Steering is a simple
## seek-with-acceleration model.
## ============================================================================

@export var field_id: String = "default"
@export var move_speed: float = 220.0
@export var acceleration: float = 900.0
@export var rotate_to_face_velocity: bool = false

var _field: FlowField


func _ready() -> void:
	var manager: FlowFieldManager = get_node_or_null("/root/FlowFieldManager") as FlowFieldManager
	if manager != null:
		_field = manager.get_field(field_id)
	if _field == null:
		push_warning("FlowFieldAgent: field '%s' not found. Did you register it with FlowFieldManager?" % field_id)


func set_field(field: FlowField) -> void:
	_field = field


func _physics_process(delta: float) -> void:
	if _field == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var target_velocity: Vector2 = _get_steering_velocity()
	velocity = velocity.move_toward(target_velocity, acceleration * delta)

	if rotate_to_face_velocity and velocity.length_squared() > 4.0:
		rotation = velocity.angle()

	move_and_slide()


func _get_steering_velocity() -> Vector2:
	if not _field.is_reachable(global_position):
		return Vector2.ZERO

	var flow_dir: Vector2 = _field.query(global_position)
	if flow_dir == Vector2.ZERO:
		return Vector2.ZERO

	return flow_dir * move_speed
