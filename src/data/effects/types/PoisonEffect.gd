class_name PoisonEffect extends ActiveEffect

var time_elapsed: float = 0.0

func _init(effect_data: EffectData):
	data = effect_data as PoisonEffectData
	if not data:
		push_error("PoisonEffect must receive a PoisonEffectData")

func tick(delta: float) -> void:
	time_elapsed += delta
	
	if is_instance_valid(_target) and _target is Enemy:
		var health = _target.health
		if health:
			var poison_data = data as PoisonEffectData
			var current_dps: float = poison_data.damage_per_second * pow(poison_data.lambda, time_elapsed)
			var damage_amount: float = current_dps * delta
			health.damage(damage_amount, poison_data.damage_type)
			
		if data.duration != INF and time_elapsed >= data.duration:
			_target.remove_effect(self)
