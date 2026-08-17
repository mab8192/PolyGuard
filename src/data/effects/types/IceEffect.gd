class_name IceEffect extends ActiveEffect

func _init(effect_data: EffectData = null):
	super._init(effect_data)
	if effect_data:
		data = effect_data as IceEffectData

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target):
		var p = CPUParticles2D.new()
		p.name = "IceParticles"
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
		p.color = Color(0.6, 0.95, 1.0, 0.9)
		target.add_child(p)
		_visual_node = p
