class_name Enemy extends CharacterBody2D

enum EnemyType {PHYSICAL, GHOST}

@export var lives_penalty: int = 1
@export var gold_reward: int = 1
@export var type: EnemyType = EnemyType.PHYSICAL

@export_category("Components")
@export var health: HealthComponent
@export var movement: MovementComponent
@export var nav: NavigationComponent

var _active_effects: Array[ActiveEffect] = []

func apply_effect(effect: ActiveEffect) -> void:
	_active_effects.append(effect)
	effect.apply(self)

func remove_effect(effect: ActiveEffect) -> void:
	_active_effects.erase(effect)
	effect.remove()

func _ready() -> void:
	if health:
		health.died.connect(_on_died)
	
	if nav:
		nav.velocity_computed.connect(_on_velocity_computed)
		
		if type == EnemyType.GHOST:
			nav.agent.navigation_layers = 4
			collision_layer = 8 # Layer 4: Ghost Enemies
			collision_mask = 9  # Collides with Layer 1 Walls (1) and Layer 4 Ghost Enemies (8)
		else:
			collision_layer = 4 # Layer 3: Physical Enemies
			collision_mask = 7  # Collides with Layer 1 Walls (1), Layer 2 Towers (2), and Layer 3 Physical Enemies (4)
		
		# Apply common settings shared by all enemies
		nav.agent.path_max_distance = 10
		nav.agent.avoidance_enabled = true

		# Assign targets from the stage
		var targets: Array[Node2D] = []
		for exit in get_tree().get_nodes_in_group("exits"):
			targets.append(exit)
		nav.set_targets(targets)

func _process(delta: float) -> void:
	for effect in _active_effects:
		effect.tick(delta)

func _on_died() -> void:
	SignalBus.enemy_died.emit(self)
	queue_free()

func _on_velocity_computed(vel: Vector2):
	var dir = vel.normalized()
	movement.handle_movement(dir, get_physics_process_delta_time())
	look_at(global_position + velocity)
