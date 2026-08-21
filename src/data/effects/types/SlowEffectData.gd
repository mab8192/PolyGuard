class_name SlowEffectData extends EffectData

func _init() -> void:
	speed_multiplier = 0.8

func create_instance() -> ActiveEffect:
	return SlowEffect.new(self.duplicate())
