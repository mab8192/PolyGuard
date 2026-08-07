class_name HealthComponent extends Node

signal died()

@export var max_health: float = 100
@export var armor: float = 0
@export var magic_resistance: float = 0

@onready var _health: float = max_health

## Affects how fast armor scales
const ARMOR_CONSTANT = 50

func damage(amount: float, type: AttackComponent.DamageType) -> void:
	# Ensures armor doesn't divide by zero or turn negative into health gain
	var damage_multiplier: float = 1.0

	if type == AttackComponent.DamageType.PHYSICAL:
		var effective_armor: float = max(0.0, armor)
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_armor)
	elif type == AttackComponent.DamageType.MAGIC:
		var effective_resistance: float = max(0.0, magic_resistance)
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_resistance)
	
	var final_damage: float = amount * damage_multiplier
	_health -= final_damage
	
	if _health <= 0:
		died.emit()

func heal(amount: float) -> void:
	_health += amount
	_health = min(_health, max_health)

func get_health() -> float:
	return _health
