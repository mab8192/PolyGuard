class_name FreezeEffectData extends EffectData

func _init() -> void:
	speed_multiplier = 0.0

func create_instance() -> ActiveEffect:
	return FreezeEffect.new(self.duplicate())
