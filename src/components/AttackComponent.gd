class_name AttackComponent extends Node

enum DamageType { PHYSICAL, PIERCING, MAGIC }

@export var damage: float
@export var damage_type: DamageType
@export var cooldown: float = 1000.0  ## Attack cooldown time in ms

var last_attack_time: float = -INF

func can_attack() -> bool:
	return Time.get_ticks_msec() - last_attack_time > cooldown

## Find hitboxes in the attack region and do something?
func attack():
	last_attack_time = Time.get_ticks_msec()
