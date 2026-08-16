class_name IceEffect extends ActiveEffect

func _init(effect_data: EffectData):
	super._init(effect_data)
	data = effect_data as IceEffectData
	if not data:
		push_error("IceEffect must receive an IceEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target) and target is Enemy and target.movement:
		target.movement.acceleration_multiplier *= (data as IceEffectData).acceleration_multiplier

func remove() -> void:
	if is_instance_valid(_target) and _target is Enemy and _target.movement:
		var mult = (data as IceEffectData).acceleration_multiplier
		if mult > 0.0:
			_target.movement.acceleration_multiplier /= mult
