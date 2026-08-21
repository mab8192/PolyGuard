class_name MagicResistanceReductionEffectData extends EffectData

func _init() -> void:
	magic_resistance_reduction = 20.0

func create_instance() -> ActiveEffect:
	return MagicResistanceReductionEffect.new(self)
