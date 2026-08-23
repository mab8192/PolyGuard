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

var _effect_applier: EffectApplierComponent
var effect_applier: EffectApplierComponent:
	get:
		if _effect_applier: return _effect_applier
		_effect_applier = ComponentUtil.get_component(self, EffectApplierComponent) as EffectApplierComponent
		return _effect_applier

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
	_effect_applier = ComponentUtil.get_component(self, EffectApplierComponent) as EffectApplierComponent
	var _er = effect_receiver

	position_history.append(global_position)
	if health:
		health.died.connect(_on_died)
	
	if nav:
		nav.velocity_computed.connect(_on_velocity_computed)
		nav.no_path_available.connect(_on_no_path_available)
		
		if data and data.type == EnemyData.EnemyType.GHOST:
			collision_layer = 8 # Layer 4: Ghost Enemies
			collision_mask = 17 # Collides with Layer 1 Walls (1) and Layer 5 Spectral Towers (16)
		else:
			collision_layer = 4 # Layer 3: Physical Enemies
			collision_mask = 19 # Collides with Layer 1 Walls (1), Layer 2 Towers (2), and Layer 5 Spectral Towers (16)

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
	
func is_attacking() -> bool:
	var should_attack: bool = (nav and nav.data and nav.data.targets_towers) or (nav and not nav.can_reach_exit())
	return should_attack and targeting != null and attack != null and targeting.get_targets().size() > 0

func _physics_process(delta: float) -> void:
	if position_history.is_empty():
		position_history.append(global_position)
	elif global_position.distance_squared_to(position_history.back()) >= HISTORY_SAMPLE_DIST_SQ:
		if position_history.size() >= MAX_HISTORY_POINTS:
			position_history.remove_at(0)
		position_history.append(global_position)

	if is_attacking():
		if nav and nav.is_active:
			nav.stop()
		if movement:
			movement.stop()
		var targets_list = targeting.get_targets()
		attack.attack_targets(targets_list)
		if not targets_list.is_empty() and is_instance_valid(targets_list[0]):
			var target_angle = (targets_list[0].global_position - global_position).angle()
			rotation = lerp_angle(rotation, target_angle, 16.0 * delta)
	else:
		if nav and not nav.is_active:
			nav.resume()

func _on_died() -> void:
	queue_free()
	SignalBus.enemy_died.emit(self)

func _on_velocity_computed(vel: Vector2) -> void:
	var delta: float = get_physics_process_delta_time()
	if is_attacking():
		if movement:
			movement.stop()
		return

	var dir: Vector2 = vel.normalized()
	if movement:
		movement.handle_movement(dir, delta)
	if vel.length_squared() > 0.1:
		rotation = lerp_angle(rotation, vel.angle(), 16.0 * delta)

func _on_no_path_available() -> void:
	pass

func apply_wave_scaling(hp_mult: float, speed_mult: float = 1.0, bounty_mult: float = 1.0) -> void:
	if health and health.data:
		health.data.max_health = round(health.data.max_health * hp_mult)
		health._health = health.data.max_health
		if health._health_bar:
			health._health_bar.max_value = health.data.max_health
			health._health_bar.value = health._health
	if movement and movement.data and speed_mult != 1.0:
		movement.data.max_speed *= speed_mult
	if data:
		data.energy_reward = maxi(1, int(round(float(data.energy_reward) * bounty_mult)))

func get_stats() -> Dictionary:
	if data:
		return data.get_stats()
	return {}
