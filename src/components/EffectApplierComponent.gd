class_name EffectApplierComponent extends Area2D

@export var delay: float = 0 ## Delay in seconds from the enemy entering the area that the effect is applied
@export var effects: Array[EffectData]

## Node2D -> Array[ActiveEffect]
var _applied_effects: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		_applied_effects[body] = []
		for effect in effects:
			var ac = effect.create_instance()
			body.apply_effect(ac)
			_applied_effects[body].append(ac)

func _on_body_exited(body: Node2D) -> void:
	if body is Enemy:
		for effect in _applied_effects[body]:
			body.remove_effect(effect)
		_applied_effects.erase(body)
