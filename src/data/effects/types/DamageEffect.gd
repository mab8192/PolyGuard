class_name DamageEffect extends ActiveEffect

func _init(effect_data: EffectData):
	data = effect_data as DamageEffectData
	if not data:
		push_error("DamageEffect must receive a DamageEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target) and target is Enemy and target.health:
		var dmg_data = data as DamageEffectData
		target.health.damage(dmg_data.damage, dmg_data.damage_type)
		
		# Puncture impact sparks
		var p = CPUParticles2D.new()
		p.name = "SpikeImpactParticles"
		p.amount = 12
		p.lifetime = 0.35
		p.one_shot = true
		p.explosiveness = 0.95
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 8.0
		p.direction = Vector2(0, -1)
		p.spread = 55.0
		p.initial_velocity_min = 45.0
		p.initial_velocity_max = 90.0
		p.gravity = Vector2(0, 180)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 3.8
		p.color = Color(0.95, 0.85, 0.65, 0.95)
		target.add_child(p)
		p.emitting = true
	
	# Instantly expire
	expired.emit()
