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
		_displace_enemy(enemy, distance)

func _displace_enemy(enemy: Enemy, distance: float) -> void:
	if not is_instance_valid(enemy):
		return
	
	var nav = enemy.nav
	var reverse_dir: Vector2 = Vector2.ZERO
	
	if nav and nav.agent:
		var next_pos = nav.agent.get_next_path_position()
		var forward_dir = enemy.global_position.direction_to(next_pos)
		if forward_dir.length_squared() > 0.01:
			reverse_dir = -forward_dir
		elif enemy.velocity.length_squared() > 0.01:
			reverse_dir = -enemy.velocity.normalized()
		else:
			reverse_dir = Vector2.LEFT
	elif enemy.velocity.length_squared() > 0.01:
		reverse_dir = -enemy.velocity.normalized()
	else:
		reverse_dir = Vector2.LEFT

	var target_pos = enemy.global_position + reverse_dir * distance
	
	if nav and nav.agent:
		var map = nav.agent.get_navigation_map()
		if map.is_valid():
			target_pos = NavigationServer2D.map_get_closest_point(map, target_pos)

	enemy.global_position = target_pos
	if enemy.movement:
		enemy.movement.stop()
	if nav and nav.agent:
		nav.agent.set_velocity(Vector2.ZERO)
