class_name Enemy extends CharacterBody2D

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

var _effect_receiver: EffectReceiverComponent
var effect_receiver: EffectReceiverComponent:
	get:
		if _effect_receiver: return _effect_receiver
		_effect_receiver = ComponentUtil.get_component(self, EffectReceiverComponent) as EffectReceiverComponent
		if not _effect_receiver:
			_effect_receiver = EffectReceiverComponent.new()
			_effect_receiver.name = "EffectReceiverComponent"
			add_child(_effect_receiver)
		return _effect_receiver

var position_history: Array[Vector2] = []
const HISTORY_SAMPLE_DIST_SQ: float = 64.0 ## Sample point every 8px moved
const MAX_HISTORY_POINTS: int = 500

func apply_effect(effect: ActiveEffect) -> void:
	if effect_receiver:
		effect_receiver.apply_effect(effect)

func has_effect(effect_name: String) -> bool:
	return effect_receiver.has_effect(effect_name) if effect_receiver else false

func get_effect(effect_name: String) -> ActiveEffect:
	return effect_receiver.get_effect(effect_name) if effect_receiver else null

func get_active_effects() -> Array[ActiveEffect]:
	return effect_receiver.get_active_effects() if effect_receiver else []

func remove_effect(effect: ActiveEffect) -> void:
	if effect_receiver:
		effect_receiver.remove_effect(effect)

func _ready() -> void:
	_health = ComponentUtil.get_component(self, HealthComponent) as HealthComponent
	_movement = ComponentUtil.get_component(self, MovementComponent) as MovementComponent
	_nav = ComponentUtil.get_component(self, NavigationComponent) as NavigationComponent
	_splitter = ComponentUtil.get_component(self, SplitterComponent) as SplitterComponent
	_attack = ComponentUtil.get_component(self, AttackComponent) as AttackComponent
	_targeting = ComponentUtil.get_component(self, TargetingComponent) as TargetingComponent
	var _er = effect_receiver

	position_history.append(global_position)
	if health:
		health.died.connect(_on_died)
	
	if nav:
		nav.velocity_computed.connect(_on_velocity_computed)
		nav.no_path_available.connect(_on_no_path_available)
		if nav.agent:
			nav.agent.velocity_computed.connect(_on_velocity_computed)
		
		if data and data.type == EnemyData.EnemyType.GHOST:
			collision_layer = 8 # Layer 4: Ghost Enemies
			collision_mask = 25 # Collides with Layer 1 Walls (1), Layer 4 Ghost Enemies (8), and Layer 5 Spectral Towers (16)
		else:
			collision_layer = 4 # Layer 3: Physical Enemies
			collision_mask = 23 # Collides with Layer 1 Walls (1), Layer 2 Towers (2), Layer 3 Physical Enemies (4), and Layer 5 Spectral Towers (16)

		SignalBus.exits_updated.connect(_on_exits_updated)
		_on_exits_updated()

func _on_exits_updated() -> void:
	if not nav:
		return
	var targets: Array[Node2D] = []
	for exit in get_tree().get_nodes_in_group("exits"):
		if exit is Exit and exit.is_active:
			targets.append(exit)
		elif exit is Node2D:
			targets.append(exit)
	nav.set_exits(targets)
	
func _physics_process(_delta: float) -> void:
	if position_history.is_empty():
		position_history.append(global_position)
	elif global_position.distance_squared_to(position_history.back()) >= HISTORY_SAMPLE_DIST_SQ:
		if position_history.size() >= MAX_HISTORY_POINTS:
			position_history.remove_at(0)
		position_history.append(global_position)

	var should_attack: bool = (nav and nav.data and nav.data.targets_towers) or (nav and not nav.can_reach_exit())
	if should_attack and targeting and attack and targeting.get_targets().size() > 0:
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

func get_stats() -> Dictionary:
	if data:
		return data.get_stats()
	return {}
