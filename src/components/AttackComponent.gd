class_name AttackComponent extends Node

enum DamageType { PHYSICAL, PIERCING, MAGIC }

@export var damage: float
@export var damage_type: DamageType

func deal_damage(health_comp: HealthComponent):
	health_comp.damage(damage)
