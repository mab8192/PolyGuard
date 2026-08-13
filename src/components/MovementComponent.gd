class_name MovementComponent extends Node

## Manages 2D movement physics (acceleration, friction, max speed) for a CharacterBody2D parent.

@export var data: MovementData

var _body: CharacterBody2D

func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"MovementComponent", self)
	if not _body:
		if get_parent() is CharacterBody2D:
			_body = get_parent() as CharacterBody2D
		else:
			push_error("MovementComponent needs a CharacterBody2D parent or assigned body reference!")

var speed_multiplier: float = 1.0

func get_speed() -> float:
	if not data:
		return 0.0
	return data.max_speed * speed_multiplier

## Accelerates towards a direction vector and applies friction when direction is zero.
func handle_movement(direction: Vector2, delta: float) -> void:
	if not _body:
		return

	var current_max_speed = get_speed()
	if direction != Vector2.ZERO:
		var dir_norm: Vector2 = direction.normalized()
		_body.velocity = _body.velocity.move_toward(dir_norm * current_max_speed, data.acceleration * delta)
	else:
		_body.velocity = _body.velocity.move_toward(Vector2.ZERO, data.friction * delta)

	if _body.velocity.length() > current_max_speed:
		_body.velocity = _body.velocity.normalized() * current_max_speed

	_body.move_and_slide()

## Instantly stops all movement velocity.
func stop() -> void:
	if _body:
		_body.velocity = Vector2.ZERO

## Applies an instant impulse force (useful for knockback, dashes, or wind).
func apply_impulse(impulse: Vector2) -> void:
	if _body:
		_body.velocity += impulse
