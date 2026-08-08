class_name AttackComponent extends Node

signal attacked(target: Node2D)

enum DamageType {PHYSICAL, MAGIC, TRUE}
enum AttackType {PROJECTILE, MELEE, CONTINUOUS}

var damage: float = 10.0
var damage_type: DamageType = DamageType.PHYSICAL
var attack_type: AttackType = AttackType.PROJECTILE
var cooldown: float = 1000.0
var attack_point: Marker2D

@export_group("Ranged Settings")
@export var projectile_scene: PackedScene ## Scene to spawn for PROJECTILE attacks
var projectile_speed: float = 400.0

var can_target_physical: bool = true
var can_target_ghost: bool = false

var targeting: TargetingComponent ## Automatically discovered in _ready

var last_attack_time: float = - INF

func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"AttackComponent", self)
		targeting = ComponentUtil.get_component(get_parent(), TargetingComponent) as TargetingComponent
		if not attack_point:
			attack_point = get_parent().find_child("Marker2D", false, false) as Marker2D

func can_attack() -> bool:
	return Time.get_ticks_msec() - last_attack_time >= cooldown

func attack_target(target: Node2D) -> void:
	if not can_attack() or not is_instance_valid(target):
		return
	
	last_attack_time = Time.get_ticks_msec()
	
	match attack_type:
		AttackType.PROJECTILE:
			_spawn_projectile(target)
		AttackType.MELEE, AttackType.CONTINUOUS:
			_deal_direct_damage(target)
	
	attacked.emit(target)

func attack_targets(targets: Array) -> void:
	if not can_attack() or targets.is_empty():
		return
	
	last_attack_time = Time.get_ticks_msec()
	
	for t in targets:
		if is_instance_valid(t) and t is Node2D:
			match attack_type:
				AttackType.PROJECTILE:
					_spawn_projectile(t)
				AttackType.MELEE, AttackType.CONTINUOUS:
					_deal_direct_damage(t)
			attacked.emit(t)

func _spawn_projectile(target: Node2D) -> void:
	if not projectile_scene:
		var parent_name = owner.name if owner else (get_parent().name if get_parent() else "node")
		push_warning("AttackComponent on %s has AttackType.PROJECTILE but no projectile_scene assigned." % parent_name)
		return
	
	var proj = projectile_scene.instantiate() as Projectile
	if not proj:
		push_error("Projectile scene must inherit from Projectile!")
		return

	add_child(proj)
	if attack_point:
		proj.global_position = attack_point.global_position
	elif get_parent() is Node2D:
		proj.global_position = (get_parent() as Node2D).global_position

	# Top-down sync from tower data and AttackComponent to Projectile tree
	var parent_node = get_parent()
	if parent_node and &"data" in parent_node and parent_node.data:
		ComponentUtil.sync_properties(parent_node.data, proj)
	ComponentUtil.sync_properties(self, proj)
	
	proj.target = target

func _deal_direct_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		health.damage(damage, damage_type)
