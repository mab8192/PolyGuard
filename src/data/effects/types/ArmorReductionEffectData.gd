class_name ArmorReductionEffectData extends EffectData

@export var armor_reduction: float = 20.0

func create_instance() -> ActiveEffect:
	return ArmorReductionEffect.new(self)
