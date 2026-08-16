class_name DisplaceEffect extends ActiveEffect

func _init(effect_data: EffectData):
	super._init(effect_data)
	data = effect_data as DisplaceEffectData
	if not data:
		push_error("DisplaceEffect must receive a DisplaceEffectData")

func apply(target: Node2D) -> void:
	super.apply(target)
	if is_instance_valid(target) and target is Enemy:
		var enemy = target as Enemy
		var distance: float = (data as DisplaceEffectData).displace_distance
		_displace_enemy_along_path(enemy, distance)

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
				# Trim history up to this segment and append new position
				history.resize(trim_index + 1)
				history.append(target_pos)
				break
			else:
				remaining_dist -= seg_len
				current_point = prev_point
				trim_index -= 1

		# If distance exceeded all recorded path history, reset to earliest recorded point
		if remaining_dist > 0.0 and not history.is_empty():
			target_pos = history[0]
			history.clear()
			history.append(target_pos)
	else:
		target_pos = enemy.global_position

	# Spawn visual warp effect at the destination
	_spawn_warp_visual(enemy, target_pos)

	enemy.global_position = target_pos
	if enemy.movement:
		enemy.movement.stop()
	if enemy.nav and enemy.nav.agent:
		enemy.nav.agent.set_velocity(Vector2.ZERO)
		enemy.nav.agent.target_position = enemy.nav.agent.target_position

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
	p.spread = 180.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.85, 0.35, 1.0, 0.9)
	enemy.get_parent().add_child(p)
	p.global_position = pos
	var timer = enemy.get_tree().create_timer(0.5)
	timer.timeout.connect(func(): if is_instance_valid(p): p.queue_free())
