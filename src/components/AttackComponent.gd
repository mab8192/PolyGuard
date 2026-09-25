class_name AttackComponent extends Node

signal attacked(target: Node2D)

@export var data: AttackData

const WALL_LAYER: int = 1

## Projectile scene -> [hitbox Shape2D, hitbox transform relative to the projectile]
static var _projectile_hitboxes: Dictionary = {}

var attack_points: Array[Marker2D] = []
var targeting: TargetingComponent ## Automatically discovered in _ready
var last_attack_time: float = - INF
var _time: float = 0
## How long a target must be lost before the next one requires a fresh aim time
const AIM_RESET_GAP: float = 0.5
var _aiming: bool = false
var _held_target_this_frame: bool = false
var _time_without_target: float = 0.0
var _projectile_hitbox: Shape2D = null
var _projectile_hitbox_xform: Transform2D = Transform2D.IDENTITY
var _shot_query: PhysicsShapeQueryParameters2D = null

func _ready() -> void:
	if not data:
		push_error("Missing AttackData! %s" % get_path())
	
	if get_parent():
		get_parent().set_meta(&"AttackComponent", self)
		targeting = ComponentUtil.get_component(get_parent(), TargetingComponent) as TargetingComponent
		_find_attack_points()

	if targeting and data and data.attack_mode == AttackData.AttackMode.PROJECTILE and data.projectile_scene:
		_load_projectile_hitbox(data.projectile_scene)
		if _projectile_hitbox:
			targeting.line_of_sight_check = can_projectile_reach

func _load_projectile_hitbox(scene: PackedScene) -> void:
	if not _projectile_hitboxes.has(scene):
		var entry: Array = [null, Transform2D.IDENTITY]
		var proj := scene.instantiate()
		if proj:
			var damage_comp := ComponentUtil.get_component(proj, DamageComponent) as DamageComponent
			var hitbox: CollisionShape2D = damage_comp.get_node_or_null("CollisionShape2D") as CollisionShape2D if damage_comp else null
			if hitbox and hitbox.shape:
				entry = [hitbox.shape, damage_comp.transform * hitbox.transform]
			proj.free()
		_projectile_hitboxes[scene] = entry
	_projectile_hitbox = _projectile_hitboxes[scene][0]
	_projectile_hitbox_xform = _projectile_hitboxes[scene][1]

## True if a shot fired now would reach the target before touching a wall. Sweeps the projectile's
## real hitbox because a zero-width ray can slip past a wall corner that the projectile then clips.
func can_projectile_reach(target: Node2D) -> bool:
	var shooter := get_parent() as CanvasItem
	if not is_instance_valid(target) or not shooter or not shooter.is_inside_tree():
		return false
	var space := shooter.get_world_2d().direct_space_state
	if not space:
		return true

	var from_pos := _get_spawn_position(target)
	var motion := target.global_position - from_pos
	if not _shot_query:
		_shot_query = PhysicsShapeQueryParameters2D.new()
		if shooter is CollisionObject2D:
			_shot_query.exclude = [(shooter as CollisionObject2D).get_rid()]
	_shot_query.shape = _projectile_hitbox
	_shot_query.transform = Transform2D(motion.angle(), from_pos) * _projectile_hitbox_xform
	_shot_query.motion = Vector2.ZERO
	_shot_query.collision_mask = WALL_LAYER
	# cast_motion ignores shapes it starts inside of, so check the spawn point separately
	if not space.intersect_shape(_shot_query, 1).is_empty():
		return false

	var target_body := target as CollisionObject2D
	_shot_query.collision_mask = WALL_LAYER | (target_body.collision_layer if target_body else 0)
	_shot_query.motion = motion
	var fractions := space.cast_motion(_shot_query)
	if fractions.size() < 2 or fractions[1] >= 1.0:
		return true

	# Something is hit before the target's center: blocked only if that first contact is a wall
	_shot_query.transform = _shot_query.transform.translated(motion * fractions[1])
	_shot_query.motion = Vector2.ZERO
	_shot_query.collision_mask = WALL_LAYER
	return space.intersect_shape(_shot_query, 1).is_empty()

func _get_spawn_position(target: Node2D) -> Vector2:
	var spawn_pt: Marker2D = get_attack_point(target)
	if is_instance_valid(spawn_pt):
		return spawn_pt.global_position
	return (get_parent() as Node2D).global_position if get_parent() is Node2D else Vector2.ZERO

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

func _physics_process(delta: float) -> void:
	_time += delta
	if not data or data.initial_delay <= 0.0:
		return
	if _held_target_this_frame:
		_time_without_target = 0.0
	else:
		_time_without_target += delta
		if _aiming and _time_without_target >= AIM_RESET_GAP:
			_aiming = false
	_held_target_this_frame = false

## The aim timer starts when a target is acquired, not when the attacker spawns
func _hold_target() -> void:
	if not data or data.initial_delay <= 0.0:
		return
	_held_target_this_frame = true
	if not _aiming:
		_aiming = true
		last_attack_time = _time + data.initial_delay - data.cooldown

func can_attack() -> bool:
	if data and data.attack_mode == AttackData.AttackMode.CONTINUOUS: return true

	return _time - last_attack_time >= (data.cooldown if data else 0.5)

func attack_target(target: Node2D) -> void:
	if is_instance_valid(target):
		_hold_target()
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
	for t in targets:
		if is_instance_valid(t):
			_hold_target()
			break
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

	var parent_node: Node = GameManager.stage_root.effects if (GameManager.stage_root and GameManager.stage_root.effects) else get_tree().current_scene
	
	var spawn_pos: Vector2 = _get_spawn_position(target)

	if parent_node is Node2D:
		proj.position = (parent_node as Node2D).to_local(spawn_pos)
	else:
		proj.position = spawn_pos

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
	
	parent_node.add_child(proj)
	proj.reset_physics_interpolation()

func _deal_direct_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		var raw_damage = data.damage
		if data.attack_mode == AttackData.AttackMode.CONTINUOUS:
			raw_damage *= get_physics_process_delta_time() if Engine.is_in_physics_frame() else get_process_delta_time()
		
		health.damage(raw_damage, data.damage_type)
