class_name BurnEffectData extends EffectData

@export var initial_damage: float = 50
@export var damage_per_second: float = 15.0
@export var damage_type: AttackData.DamageType = AttackData.DamageType.MAGIC

func create_instance() -> ActiveEffect:
	return BurnEffect.new(self)
