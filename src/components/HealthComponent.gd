class_name HealthComponent extends Node

signal died()

@export var max_health: float = 100
@export var armor: float = 0

@onready var health: float = max_health

## Affects how fast armor scales
const ARMOR_CONSTANT = 50

func damage(amount: float) -> void:	
	# Ensures armor doesn't divide by zero or turn negative into health gain
	var effective_armor: float = max(0.0, armor) 
	var damage_multiplier: float = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_armor)
	
	var final_damage: float = amount * damage_multiplier
	health -= final_damage
	
	if health <= 0:
		died.emit()

func heal(amount: float) -> void:
	health += amount
	health = min(health, max_health)
