class_name ArmorReductionEffect extends ActiveEffect

var _applied_reduction: float = 0.0

func _init(effect_data: EffectData):
	super._init(effect_data)
	data = effect_data as ArmorReductionEffectData
	if not data:
		push_error("ArmorReductionEffect must receive an ArmorReductionEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target):
		if target is Enemy and target.health:
			var reduction = (data as ArmorReductionEffectData).armor_reduction
			_applied_reduction = reduction
			target.health.armor_reduction += reduction
		
		var p = CPUParticles2D.new()
		p.name = "CorrosiveParticles"
		p.amount = 8
		p.lifetime = 0.55
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 12.0
		p.direction = Vector2(0, -1)
		p.spread = 180.0
		p.initial_velocity_min = 15.0
		p.initial_velocity_max = 40.0
		p.gravity = Vector2(0, 25)
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0
		p.color = Color(0.75, 1.0, 0.15, 0.9)
		target.add_child(p)
		_visual_node = p

func remove() -> void:
	if is_instance_valid(_target) and _target is Enemy and _target.health:
		_target.health.armor_reduction -= _applied_reduction
	super.remove()
