class_name DisplaceEffectData extends EffectData

func _init() -> void:
	displace_distance = 200.0

func create_instance() -> ActiveEffect:
	return DisplaceEffect.new(self)
