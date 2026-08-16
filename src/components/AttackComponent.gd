class_name AttackComponent extends Node

signal attacked(target: Node2D)

@export var data: AttackData

var attack_points: Array[Marker2D] = []
var targeting: TargetingComponent ## Automatically discovered in _ready
var last_attack_time: float = - INF
var _time: float = 0

func _ready() -> void:
	if not data:
		push_error("Missing AttackData! %s" % get_path())
	
	if get_parent():
		get_parent().set_meta(&"AttackComponent", self)
		targeting = ComponentUtil.get_component(get_parent(), TargetingComponent) as TargetingComponent
		_find_attack_points()

func _find_attack_points() -> void:
	attack_points.clear()
	if not get_parent():
		return
	for child in get_parent().get_children():
		if child is Marker2D:
			attack_points.append(child)

func get_attack_point(target: Node2D = null) -> Marker2D:
	if attack_points.is_empty():
		return null
	if attack_points.size() == 1:
		return attack_points[0]
	
	if is_instance_valid(target):
		var target_pos: Vector2 = target.global_position
		var best_pt: Marker2D = attack_points[0]
		var best_dist_sq: float = best_pt.global_position.distance_squared_to(target_pos)
		for i in range(1, attack_points.size()):
			var pt = attack_points[i]
			if is_instance_valid(pt):
				var dist_sq = pt.global_position.distance_squared_to(target_pos)
				if dist_sq < best_dist_sq:
					best_dist_sq = dist_sq
					best_pt = pt
		return best_pt
	
	return attack_points.pick_random()

func _process(delta: float) -> void:
	_time += delta

func can_attack() -> bool:
	if data and data.attack_mode == AttackData.AttackMode.CONTINUOUS: return true

	return _time - last_attack_time >= (data.cooldown if data else 0.5)

func attack_target(target: Node2D) -> void:
	if not can_attack() or not is_instance_valid(target):
		return

	last_attack_time = _time
	
	match data.attack_mode:
		AttackData.AttackMode.PROJECTILE:
			_spawn_projectile(target)
		AttackData.AttackMode.MELEE, AttackData.AttackMode.CONTINUOUS:
			_deal_direct_damage(target)
	
	attacked.emit(target)

func attack_targets(targets: Array) -> void:	
	if not can_attack() or targets.is_empty():
		return
	
	last_attack_time = _time
	
	for t in targets:
		if is_instance_valid(t):
			match data.attack_mode:
				AttackData.AttackMode.PROJECTILE:
					_spawn_projectile(t)
				AttackData.AttackMode.MELEE, AttackData.AttackMode.CONTINUOUS:
					_deal_direct_damage(t)
			attacked.emit(t)

func _spawn_projectile(target: Node2D) -> void:
	if not data.projectile_scene:
		push_warning("AttackComponent on %s has AttackMode.PROJECTILE but no projectile_scene assigned." % get_path())
		return
	
	var proj = data.projectile_scene.instantiate() as Projectile
	if not proj:
		push_error("Projectile scene must inherit from Projectile!")
		return

	var parent_node: Node = get_tree().current_scene
	if GameManager and GameManager.stage_root and is_instance_valid(GameManager.stage_root.effects):
		parent_node = GameManager.stage_root.effects
	parent_node.add_child(proj)

	var spawn_pt: Marker2D = get_attack_point(target)
	if spawn_pt and is_instance_valid(spawn_pt):
		proj.global_position = spawn_pt.global_position
	elif get_parent() is Node2D:
		proj.global_position = (get_parent() as Node2D).global_position

	proj.projectile_speed = data.projectile_speed
	proj.follow_target = data.projectile_follow_target
	var dmg_comp = proj.damage_component if proj.damage_component else ComponentUtil.get_component(proj, DamageComponent) as DamageComponent
	if dmg_comp:
		dmg_comp.damage = data.damage
		dmg_comp.damage_type = data.damage_type
		if targeting and targeting.data:
			dmg_comp.targeting_mask = targeting.data.targeting_mask
		else:
			dmg_comp.targeting_mask = 4

	proj.target = target

func _deal_direct_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		var raw_damage = data.damage
		if data.attack_mode == AttackData.AttackMode.CONTINUOUS:
			raw_damage *= get_process_delta_time()
		
		health.damage(raw_damage, data.damage_type)
