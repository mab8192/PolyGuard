class_name Enemy extends CharacterBody2D

enum EnemyType {PHYSICAL, GHOST}

## Gets assigned by the EnemyData type
var data: EnemyData

var _health: HealthComponent
var health: HealthComponent:
	get:
		if _health: return _health
		_health = ComponentUtil.get_component(self, HealthComponent) as HealthComponent
		return _health

var _movement: MovementComponent
var movement: MovementComponent:
	get:
		if _movement: return _movement
		_movement = ComponentUtil.get_component(self, MovementComponent) as MovementComponent
		return _movement

var _nav: NavigationComponent
var nav: NavigationComponent:
	get:
		if _nav: return _nav
		_nav = ComponentUtil.get_component(self, NavigationComponent) as NavigationComponent
		return _nav
		
var _splitter: SplitterComponent
var splitter: SplitterComponent:
	get:
		if _splitter: return _splitter
		_splitter = ComponentUtil.get_component(self, SplitterComponent) as SplitterComponent
		return _splitter
		
var _attack: AttackComponent
var attack: AttackComponent:
	get:
		if _attack: return _attack
		_attack = ComponentUtil.get_component(self, AttackComponent) as AttackComponent
		return _attack
		
var _targeting: TargetingComponent
var targeting: TargetingComponent:
	get:
		if _targeting: return _targeting
		_targeting = ComponentUtil.get_component(self, TargetingComponent) as TargetingComponent
		return _targeting

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
		nav.set_exits(targets)
	
func _process(delta: float) -> void:
	for effect in _active_effects:
		effect.tick(delta)
	
func _physics_process(_delta: float) -> void:
	if targeting and attack and targeting.get_targets().size() > 0:
		if movement:
			movement.stop()
		attack.attack_targets(targeting.get_targets())

func _on_died() -> void:
	queue_free()
	SignalBus.enemy_died.emit(self)

func _on_velocity_computed(vel: Vector2):
	var dir = vel.normalized()
	if movement:
		movement.handle_movement(dir, get_physics_process_delta_time())
	if velocity.length_squared() > 0.1:
		look_at(global_position + velocity)

func _on_no_path_available() -> void:
	if not nav:
		return

	var path = nav.get_shortest_path_to_exit_ignoring_towers()
	var tower = nav.find_first_obstructing_tower(path)

	if is_instance_valid(tower) and not tower.is_queued_for_deletion():
		if nav and nav.agent:
			nav.agent.target_position = tower.global_position
