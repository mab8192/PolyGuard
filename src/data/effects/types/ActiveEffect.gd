class_name ActiveEffect extends RefCounted

signal expired()

var data: EffectData
var _target: Node2D
var _target_health: HealthComponent = null
var _visual_node: Node2D = null
var _original_modulate: Color = Color.WHITE

var _counting_time: bool = false
var _elapsed_time_counted: float = 0.0 ## Elapsed time since _counting_time was set
var _elapsed_time_total: float = 0.0 ## Elapsed time since the effect first applied
var _sources: Array = []

func _init(effect_data: EffectData = null):
	data = effect_data

func add_source(source: Object) -> void:
	if source and source not in _sources:
		_sources.append(source)

func remove_source(source: Object) -> void:
	_sources.erase(source)

func has_active_sources() -> bool:
	_sources = _sources.filter(func(s): return is_instance_valid(s))
	return not _sources.is_empty()

func get_source_count() -> int:
	_sources = _sources.filter(func(s): return is_instance_valid(s))
	return _sources.size()

func _get_target_health() -> HealthComponent:
	if not is_instance_valid(_target):
		return null
	if not is_instance_valid(_target_health):
		_target_health = ComponentUtil.get_component(_target, HealthComponent) as HealthComponent
	return _target_health

func count_time() -> void:
	_counting_time = true
	_elapsed_time_counted = 0.0

func stop_counting_time() -> void:
	_counting_time = false
	_elapsed_time_counted = 0.0

func apply(target: Node2D) -> void:
	_target = target
	if not is_instance_valid(target) or not data:
		return

	# Tint target if specified
	if data.target_tint != Color.WHITE:
		_original_modulate = target.modulate
		target.modulate = data.target_tint

	# If speed multiplier is zero (freeze/root), immediately halt movement
	if data.speed_multiplier <= 0.0:
		var movement = ComponentUtil.get_component(target, MovementComponent) as MovementComponent
		if movement:
			movement.stop()

	_apply_instant_effects()

	# Active VFX
	if data.active_vfx:
		var vfx = data.active_vfx.instantiate()
		if vfx:
			if vfx is CanvasItem:
				(vfx as CanvasItem).z_index = 30
				(vfx as CanvasItem).z_as_relative = false
			target.add_child(vfx)
			_visual_node = vfx
			if vfx is CPUParticles2D:
				(vfx as CPUParticles2D).emitting = true

	# If effect has no duration and is instantaneous, expire immediately
	if data.duration == 0.0 or (data.duration != INF and data.duration <= 0.001 and not data.active_vfx and data.damage_per_second == 0.0 and data.heal_per_second == 0.0 and data.speed_multiplier == 1.0 and data.acceleration_multiplier == 1.0 and data.armor_reduction == 0.0 and data.magic_resistance_reduction == 0.0):
		expired.emit()

func reapply(source: Object = null) -> void:
	if source:
		add_source(source)
	count_time()
	_elapsed_time_total = 0.0

	if not is_instance_valid(_target) or not data:
		return

	# If speed multiplier is zero (freeze/root), immediately halt movement
	if data.speed_multiplier <= 0.0:
		var movement = ComponentUtil.get_component(_target, MovementComponent) as MovementComponent
		if movement:
			movement.stop()

	_apply_instant_effects()

func _apply_instant_effects() -> void:
	if not is_instance_valid(_target) or not data:
		return

	# Instant / Initial Damage
	var total_initial: float = data.damage + data.initial_damage
	if total_initial > 0.0:
		var health_comp := _get_target_health()
		if health_comp:
			health_comp.damage(total_initial, data.damage_type)

	# Instant Heal
	if data.heal_amount > 0.0:
		var health_comp := _get_target_health()
		if health_comp:
			health_comp.heal(data.heal_amount)

	# Displacement along recorded path history
	if data.displace_distance > 0.0:
		_displace_enemy_along_path(_target as Enemy, data.displace_distance)

	# Impulse force (Newton-seconds)
	if data.impulse_force > 0.0:
		var mov = ComponentUtil.get_component(_target, MovementComponent) as MovementComponent
		if mov:
			var dir = _get_source_direction()
			mov.apply_impulse(dir * data.impulse_force)

	# Impact VFX
	if data.impact_vfx:
		var imp = data.impact_vfx.instantiate()
		if imp:
			if imp is CanvasItem:
				(imp as CanvasItem).z_index = 30
				(imp as CanvasItem).z_as_relative = false
			var parent_node = _target.get_parent() if _target.get_parent() else _target
			if imp is Node2D:
				if parent_node is Node2D:
					(imp as Node2D).position = (parent_node as Node2D).to_local(_target.global_position)
				else:
					(imp as Node2D).position = _target.global_position
			parent_node.add_child(imp)
			if imp is Node2D:
				(imp as Node2D).reset_physics_interpolation()
			if imp is CPUParticles2D:
				(imp as CPUParticles2D).emitting = true
				if (imp as CPUParticles2D).one_shot:
					imp.finished.connect(func(): if is_instance_valid(imp): imp.queue_free())

func _get_source_direction() -> Vector2:
	_sources = _sources.filter(func(s): return is_instance_valid(s))
	if not _sources.is_empty():
		var src = _sources[0]
		if src is Node2D:
			return Vector2.RIGHT.rotated((src as Node2D).global_rotation)
	return Vector2.RIGHT

func tick(delta: float) -> void:
	if _counting_time:
		_elapsed_time_counted += delta
	_elapsed_time_total += delta

	# Damage Over Time (with optional lambda exponential decay)
	if data.damage_per_second > 0.0 and is_instance_valid(_target):
		var health_comp := _get_target_health()
		if health_comp:
			var current_dps: float = data.damage_per_second
			if data.lambda != 1.0 and data.lambda > 0.0:
				current_dps *= pow(data.lambda, _elapsed_time_total)
			var damage_amount: float = current_dps * delta
			health_comp.damage(damage_amount, data.damage_type)

	# Healing Over Time
	if data.heal_per_second > 0.0 and is_instance_valid(_target):
		var health_comp := _get_target_health()
		if health_comp:
			var heal_amount_tick: float = data.heal_per_second * delta
			health_comp.heal(heal_amount_tick)

	if data.duration != INF and _elapsed_time_counted >= data.duration:
		_counting_time = false
		expired.emit()
	
func remove() -> void:
	if is_instance_valid(_target) and data and data.target_tint != Color.WHITE:
		_target.modulate = _original_modulate
	if is_instance_valid(_visual_node):
		_visual_node.queue_free()
		_visual_node = null

func _displace_enemy_along_path(enemy: Enemy, distance: float) -> void:
	if not is_instance_valid(enemy):
		return

	var history = enemy.position_history
	var target_pos: Vector2 = enemy.global_position

	if not history.is_empty():
		var remaining_dist: float = distance
		var current_point: Vector2 = enemy.global_position
		var trim_index: int = history.size() - 1

		while trim_index >= 0 and remaining_dist > 0.0:
			var prev_point: Vector2 = history[trim_index]
			var seg_len: float = current_point.distance_to(prev_point)

			if seg_len <= 0.01:
				trim_index -= 1
				continue

			if remaining_dist <= seg_len:
				var t: float = remaining_dist / seg_len
				target_pos = current_point.lerp(prev_point, t)
				remaining_dist = 0.0
				history.resize(trim_index + 1)
				history.append(target_pos)
				break
			else:
				remaining_dist -= seg_len
				current_point = prev_point
				trim_index -= 1

		if remaining_dist > 0.0 and not history.is_empty():
			target_pos = history[0]
			history.clear()
			history.append(target_pos)
	else:
		target_pos = enemy.global_position

	_spawn_warp_visual(enemy, target_pos)

	enemy.global_position = target_pos
	enemy.reset_physics_interpolation()
	if enemy.movement:
		enemy.movement.stop()
	if enemy.nav:
		enemy.nav.stop()
		enemy.nav.resume()

func _spawn_warp_visual(enemy: Enemy, pos: Vector2) -> void:
	if not is_instance_valid(enemy) or not enemy.get_parent():
		return
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.4
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0
	p.direction = Vector2(0, -1)
	p.gravity = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.85, 0.35, 1.0, 0.9)
	var parent_node = enemy.get_parent()
	if parent_node is Node2D:
		p.position = (parent_node as Node2D).to_local(pos)
	else:
		p.position = pos
	parent_node.add_child(p)
	p.reset_physics_interpolation()
	var timer = enemy.get_tree().create_timer(0.5)
	timer.timeout.connect(func(): if is_instance_valid(p): p.queue_free())
