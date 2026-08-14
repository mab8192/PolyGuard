class_name PoisonEffect extends ActiveEffect

func _init(effect_data: EffectData):
	data = effect_data as PoisonEffectData
	if not data:
		push_error("PoisonEffect must receive a PoisonEffectData")

func tick(delta: float) -> void:
	super.tick(delta)
	
	if is_instance_valid(_target) and _target is Enemy:
		var health = _target.health
		if health:
			var poison_data = data as PoisonEffectData
			var current_dps: float = poison_data.damage_per_second * pow(poison_data.lambda, _elapsed_time_total)
			var damage_amount: float = current_dps * delta
			health.damage(damage_amount, poison_data.damage_type)
