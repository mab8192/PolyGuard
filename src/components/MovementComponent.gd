class_name MovementComponent extends Node

## Manages 2D movement physics (acceleration, max speed) for a CharacterBody2D parent.

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

var _effect_receiver: EffectReceiverComponent
var effect_receiver: EffectReceiverComponent:
	get:
		if _effect_receiver: return _effect_receiver
		var target_node = _body if _body else get_parent()
		if target_node:
			_effect_receiver = ComponentUtil.get_component(target_node, EffectReceiverComponent) as EffectReceiverComponent
		return _effect_receiver

var speed_multiplier: float = 1.0
var acceleration_multiplier: float = 1.0

func get_speed() -> float:
	if not data:
		return 0.0
	var mult: float = speed_multiplier
	if effect_receiver:
		mult *= effect_receiver.get_speed_multiplier()
	return data.max_speed * mult

func get_acceleration() -> float:
	if not data:
		return 0.0
	var mult: float = acceleration_multiplier
	if effect_receiver:
		mult *= effect_receiver.get_acceleration_multiplier()
	return data.acceleration * mult

## Accelerates towards a direction vector and decelerates when direction is zero.
func handle_movement(direction: Vector2, delta: float) -> void:
	if not _body or not data:
		return

	var current_max_speed = get_speed()
	if current_max_speed <= 0.0:
		_body.velocity = Vector2.ZERO
		return

	var current_accel = get_acceleration()
	if direction != Vector2.ZERO:
		var dir_norm: Vector2 = direction.normalized()
		_body.velocity = _body.velocity.move_toward(dir_norm * current_max_speed, current_accel * delta)
	else:
		_body.velocity = _body.velocity.move_toward(Vector2.ZERO, current_accel * delta)

	_body.move_and_slide()

	# Deflect along collision normal tangent so enemies glide smoothly around corners
	if _body.get_slide_collision_count() > 0 and direction != Vector2.ZERO:
		for i: int in range(_body.get_slide_collision_count()):
			var col: KinematicCollision2D = _body.get_slide_collision(i)
			var n: Vector2 = col.get_normal()
			if direction.dot(n) < 0.0:
				var tangent: Vector2 = direction.slide(n)
				if tangent.length_squared() > 0.01:
					_body.velocity = tangent.normalized() * current_max_speed

## Instantly stops all movement velocity.
func stop() -> void:
	if _body:
		_body.velocity = Vector2.ZERO

## Applies an instant impulse force (useful for knockback, dashes, or wind).
func apply_impulse(impulse: Vector2) -> void:
	if _body:
		_body.velocity += impulse
