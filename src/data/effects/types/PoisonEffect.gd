class_name PoisonEffect extends ActiveEffect

func _init(effect_data: EffectData):
	data = effect_data as PoisonEffectData
	if not data:
		push_error("PoisonEffect must receive a PoisonEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target):
		var p = CPUParticles2D.new()
		p.name = "PoisonParticles"
		p.amount = 6
		p.lifetime = 0.65
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 10.0
		p.direction = Vector2(0, -1)
		p.spread = 60.0
		p.initial_velocity_min = 10.0
		p.initial_velocity_max = 30.0
		p.gravity = Vector2(0, -15)
		p.scale_amount_min = 2.5
		p.scale_amount_max = 5.0
		p.color = Color(0.3, 0.95, 0.25, 0.85)
		target.add_child(p)
		_visual_node = p

func tick(delta: float) -> void:
	super.tick(delta)
	
	if is_instance_valid(_target) and _target is Enemy:
		var health = _target.health
		if health:
			var poison_data = data as PoisonEffectData
			var current_dps: float = poison_data.damage_per_second * pow(poison_data.lambda, _elapsed_time_total)
			var damage_amount: float = current_dps * delta
			health.damage(damage_amount, poison_data.damage_type)
