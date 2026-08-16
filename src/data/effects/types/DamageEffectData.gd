class_name DamageEffectData extends EffectData

@export var damage: float = 140.0
@export var damage_type: AttackData.DamageType = AttackData.DamageType.PHYSICAL

func create_instance() -> ActiveEffect:
	return DamageEffect.new(self)
