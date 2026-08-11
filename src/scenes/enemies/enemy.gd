class_name Enemy extends CharacterBody2D

enum EnemyType {PHYSICAL, GHOST}

## Gets assigned by the EnemyData type
var data: EnemyData

var health: HealthComponent:
	get:
		return ComponentUtil.get_component(self, HealthComponent) as HealthComponent
		
var movement: MovementComponent:
	get:
		return ComponentUtil.get_component(self, MovementComponent) as MovementComponent
		
var nav: NavigationComponent:
	get:
		return ComponentUtil.get_component(self, NavigationComponent) as NavigationComponent

var _active_effects: Array[ActiveEffect] = []

func apply_effect(effect: ActiveEffect) -> void:
	_active_effects.append(effect)
	effect.apply(self)

func has_effect(effect_name: String) -> bool:
	return _active_effects.any(func(x: ActiveEffect): return x.data.name == effect_name)

func remove_effect(effect: ActiveEffect) -> void:
	_active_effects.erase(effect)
	effect.remove()

func _ready() -> void:
	if health:
		health.died.connect(_on_died)
	
	if nav:
		nav.velocity_computed.connect(_on_velocity_computed)
		nav.no_path_available.connect(_on_no_path_available)
		
		if data.type == EnemyType.GHOST:
			collision_layer = 8 # Layer 4: Ghost Enemies
			collision_mask = 9  # Collides with Layer 1 Walls (1) and Layer 4 Ghost Enemies (8)
		else:
			collision_layer = 4 # Layer 3: Physical Enemies
			collision_mask = 7  # Collides with Layer 1 Walls (1), Layer 2 Towers (2), and Layer 3 Physical Enemies (4)

		# Assign targets from the stage
		var targets: Array[Node2D] = []
		for exit in get_tree().get_nodes_in_group("exits"):
			targets.append(exit)
		nav.set_targets(targets)

func _process(delta: float) -> void:
	for effect in _active_effects:
		effect.tick(delta)

func _on_died() -> void:
	queue_free()
	SignalBus.enemy_died.emit(self)

func _on_velocity_computed(vel: Vector2):
	var dir = vel.normalized()
	movement.handle_movement(dir, get_physics_process_delta_time())
	look_at(global_position + velocity)

func _on_no_path_available() -> void:
	print("NO PATH! FINDING NEAREST TOWER TO DESTROYYYY ITTTT")
	
