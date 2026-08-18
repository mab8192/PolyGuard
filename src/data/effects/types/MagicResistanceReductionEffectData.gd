class_name MagicResistanceReductionEffectData extends EffectData

@export var magic_resistance_reduction: float = 20.0

func create_instance() -> ActiveEffect:
	return MagicResistanceReductionEffect.new(self)
