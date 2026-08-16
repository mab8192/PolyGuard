class_name BurnEffect extends ActiveEffect

func _init(effect_data: EffectData):
	data = effect_data as BurnEffectData
	if not data:
		push_error("BurnEffect must receive a BurnEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target):
		if target is Enemy and target.health:
			var burn_data = data as BurnEffectData
			target.health.damage(burn_data.initial_damage, burn_data.damage_type)
		
		var p = CPUParticles2D.new()
		p.name = "BurnParticles"
		p.amount = 8
		p.lifetime = 0.45
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 12.0
		p.direction = Vector2(0, -1)
		p.spread = 45.0
		p.initial_velocity_min = 25.0
		p.initial_velocity_max = 55.0
		p.gravity = Vector2(0, -25)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.5
		p.color = Color(1.0, 0.45, 0.1, 0.9)
		target.add_child(p)
		_visual_node = p

func tick(delta: float) -> void:
	super.tick(delta)
	if is_instance_valid(_target) and _target is Enemy:
		var health = _target.health
		if health:
			var burn_data = data as BurnEffectData
			var damage_amount: float = burn_data.damage_per_second * delta
			health.damage(damage_amount, burn_data.damage_type)
