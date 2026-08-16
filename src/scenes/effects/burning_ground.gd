class_name BurningGround extends Node2D

@export var lifetime: float = 4.0
@export var radius: float = 40.0

@onready var particles: CPUParticles2D = $FireParticles
@onready var effect_applier: EffectApplierComponent = $EffectApplierComponent

var _time_remaining: float = 4.0

func _ready() -> void:
	_time_remaining = lifetime

func _process(delta: float) -> void:
	_time_remaining -= delta
	
	# Smooth fade out in the final 0.8 seconds
	if _time_remaining <= 0.8:
		var alpha: float = maxf(0.0, _time_remaining / 0.8)
		modulate.a = alpha
		if particles and particles.emitting and _time_remaining <= 0.3:
			particles.emitting = false
	
	if _time_remaining <= 0.0:
		if effect_applier:
			effect_applier.disable()
		queue_free()

func _draw() -> void:
	# Subtle glowing ground scorch ring
	draw_circle(Vector2.ZERO, radius, Color(0.9, 0.25, 0.05, 0.18))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.5, 0.1, 0.5), 1.5, true)
