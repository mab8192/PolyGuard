class_name Bomb extends Projectile

@export var explosion_radius: float = 64.0
@export var min_damage_ratio: float = 0.25 ## Damage ratio at outer edge of explosion radius (e.g. 0.25 = 25%)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	if damage_component:
		damage_component.hit.connect(explode)

func explode(primary_target: Node2D = null) -> void:
	if GameManager and GameManager.current_stage and GameManager.current_stage.effect_manager:
		GameManager.current_stage.effect_manager.explosion(global_position, Color.DARK_RED)

	var mask: int = damage_component.collision_mask if damage_component else 4
	var base_damage: float = damage_component.damage if damage_component else 10.0
	var damage_type = damage_component.damage_type if damage_component else AttackComponent.DamageType.PHYSICAL

	var shape := CircleShape2D.new()
	shape.radius = explosion_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var space_state := get_world_2d().direct_space_state
	if not space_state:
		return

	var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
	for result in results:
		var collider = result.get("collider") as Node2D
		if not is_instance_valid(collider) or collider.is_queued_for_deletion():
			continue

		# Primary target was already damaged by DamageComponent._on_body_entered
		if collider == primary_target:
			continue

		var distance: float = global_position.distance_to(collider.global_position)
		var t: float = clamp(distance / explosion_radius, 0.0, 1.0)
		var damage_amount: float = lerp(base_damage, base_damage * min_damage_ratio, t)

		var health = ComponentUtil.get_component(collider, HealthComponent) as HealthComponent
		if health:
			health.damage(damage_amount, damage_type)
