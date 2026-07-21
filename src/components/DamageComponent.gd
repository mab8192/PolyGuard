class_name DamageComponent extends Node

@export var damage: float

func deal_damage(health_comp: HealthComponent):
	health_comp.damage(damage)
