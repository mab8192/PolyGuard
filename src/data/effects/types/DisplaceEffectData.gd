class_name DisplaceEffectData extends EffectData

@export var displace_distance: float = 200.0

func create_instance() -> ActiveEffect:
	return DisplaceEffect.new(self)
