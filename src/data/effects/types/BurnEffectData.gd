class_name BurnEffectData extends EffectData

@export var damage_per_second: float = 15.0
@export var damage_type: AttackComponent.DamageType = AttackComponent.DamageType.MAGIC

func create_instance() -> ActiveEffect:
	return BurnEffect.new(self)
