class_name PoisonEffectData extends EffectData

@export var damage_per_second: float = 15.0
@export var lambda: float = 0.9  ## Multiplier applied to damage_per_second per second (e.g. 0.9 = 10% reduction each second)
@export var damage_type: AttackData.DamageType = AttackData.DamageType.MAGIC

func create_instance() -> ActiveEffect:
	return PoisonEffect.new(self)
