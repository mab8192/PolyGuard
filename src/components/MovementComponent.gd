class_name MovementComponent extends Node

## Manages 2D movement physics (acceleration, friction, max speed) for a CharacterBody2D parent.

@export_group("Speed & Acceleration")
@export var max_speed: float = 100.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

@export_group("Target")
## Automatically detects the parent if left unassigned.
@export var body: CharacterBody2D

func _ready() -> void:
	if not body:
		if get_parent() is CharacterBody2D:
			body = get_parent() as CharacterBody2D
		else:
			push_error("MovementComponent needs a CharacterBody2D parent or assigned body reference!")

## Accelerates towards a direction vector and applies friction when direction is zero.
func handle_movement(direction: Vector2, delta: float) -> void:
	if not body:
		return

	if direction != Vector2.ZERO:
		var dir_norm: Vector2 = direction.normalized()
		body.velocity = body.velocity.move_toward(dir_norm * max_speed, acceleration * delta)
	else:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)

	body.move_and_slide()

## Instantly stops all movement velocity.
func stop() -> void:
	if body:
		body.velocity = Vector2.ZERO

## Applies an instant impulse force (useful for knockback, dashes, or wind).
func apply_impulse(impulse: Vector2) -> void:
	if body:
		body.velocity += impulse
