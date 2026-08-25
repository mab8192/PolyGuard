class_name EffectReceiverComponent extends Node

signal effect_applied(effect: ActiveEffect)
signal effect_removed(effect: ActiveEffect)
signal effects_changed()

var _active_effects: Array[ActiveEffect] = []

func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"EffectReceiverComponent", self)

func _process(delta: float) -> void:
	if _active_effects.is_empty():
		return
	for i in range(_active_effects.size() - 1, -1, -1):
		if i < _active_effects.size():
			_active_effects[i].tick(delta)

func apply_effect(effect: ActiveEffect) -> void:
	if not effect:
		return
	_active_effects.append(effect)
	if not effect.expired.is_connected(_on_effect_expired.bind(effect)):
		effect.expired.connect(_on_effect_expired.bind(effect))
	var parent_node = get_parent() as Node2D
	effect.apply(parent_node)
	effect_applied.emit(effect)
	effects_changed.emit()

func remove_effect(effect: ActiveEffect) -> void:
	if effect in _active_effects:
		_active_effects.erase(effect)
		if effect.expired.is_connected(_on_effect_expired.bind(effect)):
			effect.expired.disconnect(_on_effect_expired.bind(effect))
		effect.remove()
		effect_removed.emit(effect)
		effects_changed.emit()

func _on_effect_expired(effect: ActiveEffect) -> void:
	remove_effect(effect)

func has_effect(effect_name: String) -> bool:
	return _active_effects.any(func(x: ActiveEffect): return x.data and x.data.name == effect_name)

func get_effect(effect_name: String) -> ActiveEffect:
	for effect in _active_effects:
		if effect.data and effect.data.name == effect_name:
			return effect
	return null

func get_active_effects() -> Array[ActiveEffect]:
	return _active_effects

## Stat Queries for other components

func get_speed_multiplier() -> float:
	var mult: float = 1.0
	for effect in _active_effects:
		if effect.data:
			mult *= effect.data.speed_multiplier
	return mult

func get_acceleration_multiplier() -> float:
	var mult: float = 1.0
	for effect in _active_effects:
		if effect.data:
			mult *= effect.data.acceleration_multiplier
	return mult

func get_armor_reduction() -> float:
	var reduction: float = 0.0
	for effect in _active_effects:
		if effect.data:
			reduction = maxf(reduction, effect.data.armor_reduction)
	return reduction

func get_magic_resistance_reduction() -> float:
	var reduction: float = 0.0
	for effect in _active_effects:
		if effect.data:
			reduction = maxf(reduction, effect.data.magic_resistance_reduction)
	return reduction

func get_energy_reward_multiplier() -> float:
	var mult: float = 1.0
	for effect in _active_effects:
		if effect.data:
			mult = maxf(mult, effect.data.energy_reward_multiplier)
	return mult
