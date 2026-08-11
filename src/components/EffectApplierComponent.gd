class_name EffectApplierComponent extends Area2D

@export var data: EffectApplierData

## Node2D -> Array[ActiveEffect]
var _applied_effects: Dictionary = {}
var _enabled: bool = true

func enable() -> void:
	_enabled = true
	for body in get_overlapping_bodies():
		_on_body_entered(body)

func disable() -> void:
	_enabled = false
	for body in get_overlapping_bodies():
		_on_body_exited(body)

func _ready() -> void:
	_update_collision_mask()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _update_collision_mask() -> void:
	var mask: int = 0
	if data.can_target_physical:
		mask |= 4 # Physics Layer 3 (Physical Enemies)
	if data.can_target_ghost:
		mask |= 8 # Physics Layer 4 (Ghost Enemies)
	collision_mask = mask

func _on_body_entered(body: Node2D) -> void:
	if !_enabled: return
	
	var enemy = body as Enemy
	if enemy:
		_applied_effects[enemy] = []
		for effect in data.effects:
			var ac = effect.create_instance()
			if not enemy.has_effect(effect.name):
				enemy.apply_effect(ac)
				_applied_effects[enemy].append(ac)

func _on_body_exited(body: Node2D) -> void:
	if !_enabled: return

	for enemy in _applied_effects.keys().duplicate():
		if not is_instance_valid(enemy):
			_applied_effects.erase(enemy)

	if is_instance_valid(body) and body is Enemy and body in _applied_effects:
		for effect in _applied_effects[body]:
			body.remove_effect(effect)
		_applied_effects.erase(body)
