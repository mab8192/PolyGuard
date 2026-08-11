class_name SlowEffect extends ActiveEffect

func _init(effect_data: EffectData):
	data = effect_data as SlowEffectData
	if not data:
		push_error("SlowEffect must receive a SlowEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if target is Enemy and target.movement:
		target.movement.speed_multiplier *= data.speed_multiplier

func remove() -> void:
	if is_instance_valid(_target) and _target is Enemy and _target.movement:
		_target.movement.speed_multiplier /= data.speed_multiplier
