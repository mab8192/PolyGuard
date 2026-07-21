class_name HealthComponent extends Node

@export var max_health: float

@onready var health: float = max_health

signal died()

func damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		died.emit()

func heal(amount: float) -> void:
	health += amount
	health = min(health, max_health)
