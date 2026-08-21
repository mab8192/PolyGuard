class_name FreezeEffect extends ActiveEffect

const FROST_COLOR: Color = Color(0.45, 0.85, 1.0, 1.0)
var _original_modulate: Color = Color.WHITE

func _init(effect_data: EffectData = null):
	super._init(effect_data)

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target):
		_original_modulate = target.modulate
		target.modulate = FROST_COLOR
		
		var movement = ComponentUtil.get_component(target, MovementComponent) as MovementComponent
		if movement:
			movement.stop()
		
		var p = CPUParticles2D.new()
		p.name = "FreezeParticles"
		p.amount = 8
		p.lifetime = 0.6
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 16.0
		p.direction = Vector2(0, -1)
		p.spread = 180.0
		p.gravity = Vector2(0, 0)
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 8.0
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0
		p.color = Color(0.65, 0.95, 1.0, 0.9)
		target.add_child(p)
		_visual_node = p

func remove() -> void:
	if is_instance_valid(_target):
		_target.modulate = _original_modulate
	super.remove()
