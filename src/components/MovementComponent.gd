class_name MovementComponent extends Node

## Manages 2D movement physics (acceleration, max speed) and external Newtonian forces for a CharacterBody2D parent.

@export var data: MovementData

var _body: CharacterBody2D
var external_velocity: Vector2 = Vector2.ZERO
@export var friction: float = 500.0 ## Ground friction / drag rate in px/s² damping external forces

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

## Returns the physical mass (in kg) based on the enemy's size class
func get_mass() -> float:
	var target_node = _body if _body else get_parent()
	if target_node is Enemy and target_node.nav and target_node.nav.data:
		match target_node.nav.data.size:
			NavigationData.AgentSize.SMALL:
				return 1.0
			NavigationData.AgentSize.MEDIUM:
				return 1.8
			NavigationData.AgentSize.LARGE:
				return 3.5
	return 1.0

## Applies a continuous Newtonian force in Newtons (F = ma => a = F/m => Δv = (F/m) * dt)
func apply_force(force_newtons: Vector2, delta: float) -> void:
	var mass = get_mass()
	var acceleration = force_newtons / mass
	external_velocity += acceleration * delta

## Applies an instantaneous impulse in Newton-seconds (J = m * Δv => Δv = J/m)
func apply_impulse(impulse_ns: Vector2) -> void:
	var mass = get_mass()
	external_velocity += impulse_ns / mass

## Accelerates towards a direction vector and decelerates when direction is zero.
func handle_movement(direction: Vector2, delta: float) -> void:
	if not _body or not data:
		return

	var current_max_speed = get_speed()
	
	var self_velocity: Vector2 = Vector2.ZERO
	if direction != Vector2.ZERO and current_max_speed > 0.0:
		var dir_norm: Vector2 = direction.normalized()
		self_velocity = dir_norm * current_max_speed
	
	# Total velocity is self-propulsion plus external physics forces (wind thrust, knockback)
	_body.velocity = self_velocity + external_velocity
	
	# Ground friction decays external velocity toward zero
	if external_velocity != Vector2.ZERO:
		external_velocity = external_velocity.move_toward(Vector2.ZERO, friction * delta)

	_body.move_and_slide()

	# Deflect along collision normal tangent so enemies glide smoothly around corners
	if _body.get_slide_collision_count() > 0 and direction != Vector2.ZERO:
		for i: int in range(_body.get_slide_collision_count()):
			var col: KinematicCollision2D = _body.get_slide_collision(i)
			var n: Vector2 = col.get_normal()
			if direction.dot(n) < 0.0:
				var tangent: Vector2 = direction.slide(n)
				if tangent.length_squared() > 0.01:
					_body.velocity = tangent.normalized() * current_max_speed + external_velocity

## Instantly stops all movement velocity.
func stop() -> void:
	if _body:
		_body.velocity = Vector2.ZERO
	external_velocity = Vector2.ZERO
