class_name BurnEffect extends ActiveEffect

func _init(effect_data: EffectData = null):
	super._init(effect_data)

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target):
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
