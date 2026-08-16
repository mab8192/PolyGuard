class_name IceEffectData extends EffectData

@export var acceleration_multiplier: float = 0.15

func create_instance() -> ActiveEffect:
	return IceEffect.new(self)
