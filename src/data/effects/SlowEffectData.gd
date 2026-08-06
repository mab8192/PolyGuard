class_name SlowEffectData extends EffectData

@export var speed_multiplier: float = 0.8

func create_instance() -> ActiveEffect:
	return SlowEffect.new(self)
