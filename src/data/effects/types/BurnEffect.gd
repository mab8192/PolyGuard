class_name BurnEffect extends ActiveEffect

func _init(effect_data: EffectData):
	data = effect_data as BurnEffectData
	if not data:
		push_error("BurnEffect must receive a BurnEffectData")

func tick(delta: float) -> void:
	super.tick(delta)
	if is_instance_valid(_target) and _target is Enemy:
		var health = _target.health
		if health:
			var burn_data = data as BurnEffectData
			var damage_amount: float = burn_data.damage_per_second * delta
			health.damage(damage_amount, burn_data.damage_type)
