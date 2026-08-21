class_name PoisonEffectData extends EffectData

func _init() -> void:
	damage_per_second = 15.0
	lambda = 0.9
	damage_type = AttackData.DamageType.MAGIC

func create_instance() -> ActiveEffect:
	return PoisonEffect.new(self)
