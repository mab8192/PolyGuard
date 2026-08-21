class_name BurnEffectData extends EffectData

func _init() -> void:
	initial_damage = 50.0
	damage_per_second = 15.0
	damage_type = AttackData.DamageType.MAGIC

func create_instance() -> ActiveEffect:
	return BurnEffect.new(self)
