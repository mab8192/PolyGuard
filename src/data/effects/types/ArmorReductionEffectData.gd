class_name ArmorReductionEffectData extends EffectData

func _init() -> void:
	armor_reduction = 20.0

func create_instance() -> ActiveEffect:
	return ArmorReductionEffect.new(self)
