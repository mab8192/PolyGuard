class_name AttackComponent extends Node

signal attacked(target: Node2D)

enum DamageType { PHYSICAL, MAGIC, TRUE }
enum AttackMode { PROJECTILE, MELEE, CONTINUOUS }

@export var data: AttackData:
	set(val):
		data = val
		if data:
			apply_data(data)

var damage: float = 10.0
var damage_type: DamageType = DamageType.PHYSICAL
var attack_mode: AttackMode = AttackMode.PROJECTILE
var cooldown: float = 1000.0
var attack_point: Marker2D

@export_group("Ranged Settings")
@export var projectile_scene: PackedScene ## Scene to spawn for PROJECTILE attacks
var projectile_speed: float = 400.0

var can_target_physical: bool = true
var can_target_ghost: bool = false

var targeting: TargetingComponent ## Automatically discovered in _ready
var last_attack_time: float = - INF
var is_configured: bool = false

func apply_data(config: AttackData) -> void:
	if not config:
		return
	damage = config.damage
	damage_type = config.damage_type
	attack_mode = config.attack_mode
	cooldown = config.cooldown
	projectile_speed = config.projectile_speed
	if config.projectile_scene:
		projectile_scene = config.projectile_scene
	can_target_physical = config.can_target_physical
	can_target_ghost = config.can_target_ghost
	is_configured = true

func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"AttackComponent", self)
		targeting = ComponentUtil.get_component(get_parent(), TargetingComponent) as TargetingComponent
		if not attack_point:
			attack_point = get_parent().find_child("Marker2D", false, false) as Marker2D
	if data:
		apply_data(data)
	elif not is_configured:
		push_error("AttackComponent on %s is unconfigured! Set data or call apply_data()." % get_path())

func can_attack() -> bool:
	if attack_mode == AttackMode.CONTINUOUS: return true

	return Time.get_ticks_msec() - last_attack_time >= cooldown

func attack_target(target: Node2D) -> void:
	if not can_attack() or not is_instance_valid(target):
		return
	
	last_attack_time = Time.get_ticks_msec()
	
	match attack_mode:
		AttackMode.PROJECTILE:
			_spawn_projectile(target)
		AttackMode.MELEE, AttackMode.CONTINUOUS:
			_deal_direct_damage(target)
	
	attacked.emit(target)

func attack_targets(targets: Array) -> void:
	if not can_attack() or targets.is_empty():
		return
	
	last_attack_time = Time.get_ticks_msec()
	
	for t in targets:
		if is_instance_valid(t):
			match attack_mode:
				AttackMode.PROJECTILE:
					_spawn_projectile(t)
				AttackMode.MELEE, AttackMode.CONTINUOUS:
					_deal_direct_damage(t)
			attacked.emit(t)

func _spawn_projectile(target: Node2D) -> void:
	if not projectile_scene:
		push_warning("AttackComponent on %s has AttackMode.PROJECTILE but no projectile_scene assigned." % get_path())
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

	proj.projectile_speed = projectile_speed
	var dmg_comp = proj.damage_component if proj.damage_component else ComponentUtil.get_component(proj, DamageComponent) as DamageComponent
	if dmg_comp:
		dmg_comp.damage = damage
		dmg_comp.damage_type = damage_type
		dmg_comp.can_target_physical = can_target_physical
		dmg_comp.can_target_ghost = can_target_ghost

	proj.target = target

func _deal_direct_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		health.damage(damage, damage_type)
