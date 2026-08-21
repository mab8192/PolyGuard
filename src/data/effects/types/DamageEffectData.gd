class_name DamageEffectData extends EffectData

func _init() -> void:
	damage = 140.0
	damage_type = AttackData.DamageType.PHYSICAL

func create_instance() -> ActiveEffect:
	return DamageEffect.new(self)
