class_name MovementComponent extends Node

## Manages 2D movement physics (acceleration, friction, max speed) for a CharacterBody2D parent.

@export var data: MovementData:
	set(val):
		data = val
		if data:
			apply_data(data)

var max_speed: float = 100.0
var acceleration: float = 1200.0
var friction: float = 1000.0

var body: CharacterBody2D
var is_configured: bool = false

func apply_data(config: MovementData) -> void:
	if not config:
		return
	max_speed = config.max_speed
	acceleration = config.acceleration
	friction = config.friction
	is_configured = true

func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"MovementComponent", self)
	if not body:
		if get_parent() is CharacterBody2D:
			body = get_parent() as CharacterBody2D
		else:
			push_error("MovementComponent needs a CharacterBody2D parent or assigned body reference!")
	if data:
		apply_data(data)
	elif not is_configured:
		push_error("MovementComponent on %s is unconfigured! Set data or call apply_data()." % get_path())

## Accelerates towards a direction vector and applies friction when direction is zero.
func handle_movement(direction: Vector2, delta: float) -> void:
	if not body:
		return

	if direction != Vector2.ZERO:
		var dir_norm: Vector2 = direction.normalized()
		body.velocity = body.velocity.move_toward(dir_norm * max_speed, acceleration * delta)
	else:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)

	if body.velocity.length() > max_speed:
		body.velocity = body.velocity.normalized() * max_speed

	body.move_and_slide()

## Instantly stops all movement velocity.
func stop() -> void:
	if body:
		body.velocity = Vector2.ZERO

## Applies an instant impulse force (useful for knockback, dashes, or wind).
func apply_impulse(impulse: Vector2) -> void:
	if body:
		body.velocity += impulse
