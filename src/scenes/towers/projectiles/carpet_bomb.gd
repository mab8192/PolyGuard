class_name CarpetBomb extends Projectile

@export var explosion_radius: float = 64.0
@export var min_damage_ratio: float = 0.3
@export var carpet_patches: int = 3
@export var carpet_spacing: float = 32.0

const BURNING_GROUND_SCENE: PackedScene = preload("res://src/scenes/effects/burning_ground.tscn")

@onready var _trail: CPUParticles2D = $BombTrail

var _target_pos: Vector2 = Vector2.ZERO
var _has_target_pos: bool = false
var _exploded: bool = false

func _ready() -> void:
	super._ready()
	if damage_component:
		damage_component.collides_with_walls = false
		damage_component._update_collision_mask()
		damage_component.hit.connect(_on_damage_hit)

func _process(delta: float) -> void:
	if _exploded:
		return
	
	if is_instance_valid(target):
		_target_pos = target.global_position
		_has_target_pos = true
	
	if _trail and direction != Vector2.ZERO:
		_trail.direction = -direction
		
	# Check if passed/reached target position
	if _has_target_pos:
		var step: float = projectile_speed * delta
		var dist_sq: float = global_position.distance_squared_to(_target_pos)
		if dist_sq <= (step * 2.0) ** 2 or (direction != Vector2.ZERO and (global_position - _target_pos).dot(direction) >= 0.0):
			explode(null)
			return
		
	super._process(delta)

func _on_damage_hit(primary_target: Node2D) -> void:
	explode(primary_target)

func explode(primary_target: Node2D = null) -> void:
	if _exploded:
		return
	_exploded = true
	
	# Fiery explosion visual
	if GameManager.current_stage:
		GameManager.current_stage.effect_manager.explosion(global_position, Color(1.0, 0.45, 0.1))

	var mask: int = damage_component.collision_mask if damage_component else 4
	var base_damage: float = damage_component.damage if damage_component else 75.0
	var damage_type = damage_component.damage_type if damage_component else AttackData.DamageType.PHYSICAL

	# Deal AoE damage to physical enemies in blast radius
	var shape := CircleShape2D.new()
	shape.radius = explosion_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var space_state := get_world_2d().direct_space_state
	if space_state:
		var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
		for result in results:
			var collider = result.get("collider") as Node2D
			if not is_instance_valid(collider) or collider.is_queued_for_deletion():
				continue
			
			var enemy = collider as Enemy
			if not enemy:
				continue
				
			# Strict check: ignore ghost enemies
			if enemy.data and enemy.data.type == EnemyData.EnemyType.GHOST:
				continue

			if collider == primary_target:
				continue

			var distance: float = global_position.distance_to(collider.global_position)
			var t: float = clampf(distance / explosion_radius, 0.0, 1.0)
			var damage_amount: float = lerp(base_damage, base_damage * min_damage_ratio, t)

			var health = ComponentUtil.get_component(collider, HealthComponent) as HealthComponent
			if health:
				health.damage(damage_amount, damage_type)

	# Spawn lingering carpet of burning ground patches along the line of fire
	_spawn_burning_ground()
	
	queue_free()

func _spawn_burning_ground() -> void:
	var effects_parent: Node = GameManager.stage_root.effects if GameManager.stage_root else get_tree().current_scene

	var fwd = direction if direction != Vector2.ZERO else Vector2.RIGHT
	var offsets: Array[float] = [0.0]
	if carpet_patches >= 3:
		offsets = [-carpet_spacing, 0.0, carpet_spacing]
	elif carpet_patches == 2:
		offsets = [-carpet_spacing * 0.5, carpet_spacing * 0.5]
	
	for offset in offsets:
		var patch = BURNING_GROUND_SCENE.instantiate() as Node2D
		if patch:
			var target_pos: Vector2 = global_position + fwd * offset
			if effects_parent is Node2D:
				patch.position = (effects_parent as Node2D).to_local(target_pos)
			else:
				patch.position = target_pos
			effects_parent.add_child(patch)
			patch.reset_physics_interpolation()
