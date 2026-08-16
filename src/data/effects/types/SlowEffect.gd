class_name SlowEffect extends ActiveEffect

func _init(effect_data: EffectData):
	data = effect_data as SlowEffectData
	if not data:
		push_error("SlowEffect must receive a SlowEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target):
		if target is Enemy and target.movement:
			target.movement.speed_multiplier *= data.speed_multiplier
		
		var p = CPUParticles2D.new()
		p.name = "SlowParticles"
		p.amount = 6
		p.lifetime = 0.75
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 14.0
		p.direction = Vector2(0, 1)
		p.spread = 90.0
		p.initial_velocity_min = 5.0
		p.initial_velocity_max = 15.0
		p.gravity = Vector2(0, 10)
		p.scale_amount_min = 1.5
		p.scale_amount_max = 3.5
		p.color = Color(0.4, 0.85, 1.0, 0.85)
		target.add_child(p)
		_visual_node = p

func remove() -> void:
	if is_instance_valid(_target) and _target is Enemy and _target.movement:
		_target.movement.speed_multiplier /= data.speed_multiplier
	super.remove()
