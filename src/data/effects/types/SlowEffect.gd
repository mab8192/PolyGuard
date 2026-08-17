class_name SlowEffect extends ActiveEffect

func _init(effect_data: EffectData = null):
	super._init(effect_data)
	if effect_data:
		data = effect_data as SlowEffectData
