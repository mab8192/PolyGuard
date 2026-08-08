class_name HealthComponent extends Node

signal died()

@export var data: HealthData

var _health: float

func _ready() -> void:
	if not data:
		push_error("Missing HealthData! %s" % get_path())
	
	if get_parent():
		get_parent().set_meta(&"HealthComponent", self)

	_health = data.max_health

## Affects how fast armor scales
const ARMOR_CONSTANT = 50

func damage(amount: float, type: AttackComponent.DamageType) -> void:
	# Ensures armor doesn't divide by zero or turn negative into health gain
	var damage_multiplier: float = 1.0

	if type == AttackComponent.DamageType.PHYSICAL:
		var effective_armor: float = max(0.0, data.armor)
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_armor)
	elif type == AttackComponent.DamageType.MAGIC:
		var effective_resistance: float = max(0.0, data.magic_resistance)
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_resistance)
	
	var final_damage: float = amount * damage_multiplier
	print("Taking %f damage" % final_damage)
	_health -= final_damage
	
	if _health <= 0:
		died.emit()

func heal(amount: float) -> void:
	_health += amount
	_health = min(_health, data.max_health)

func get_health() -> float:
	return _health
