class_name IceEffectData extends EffectData

func _init() -> void:
	acceleration_multiplier = 0.15

func create_instance() -> ActiveEffect:
	return IceEffect.new(self)
