class_name AttackComponent extends Node

signal attacked(target: Node2D)

enum DamageType {PHYSICAL, MAGIC, TRUE}
enum AttackType {PROJECTILE, MELEE, CONTINUOUS}

@export_group("Attack Settings")
@export var damage: float = 10.0 ## Raw damage inflicted per attack (per projectile, per swing, or per tick)
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var attack_type: AttackType = AttackType.PROJECTILE
@export var cooldown: float = 1000.0 ## Cooldown time between attacks in ms
@export var attack_point: Marker2D

@export_group("Ranged Settings")
@export var projectile_scene: PackedScene ## Scene to spawn for PROJECTILE attacks
@export var projectile_speed: float = 400

@export_group("Optional Components")
@export var targeting: TargetingComponent ## If set, automatically attacks targeting.active_targets

var last_attack_time: float = - INF

func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"AttackComponent", self)

func can_attack() -> bool:
	return Time.get_ticks_msec() - last_attack_time >= cooldown

func attack_target(target: Node2D) -> void:
	if not can_attack() or not is_instance_valid(target):
		return
	
	last_attack_time = Time.get_ticks_msec()
	
	match attack_type:
		AttackType.PROJECTILE:
			_spawn_projectile(target)
		AttackType.MELEE:
			_deal_direct_damage(target)
		AttackType.CONTINUOUS:
			_deal_direct_damage(target)
	
	attacked.emit(target)

func attack_targets(targets: Array) -> void:
	if not can_attack() or targets.is_empty():
		return
	
	print("ATTACK!")
	
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
		push_warning("AttackComponent on %s has AttackType.PROJECTILE but no projectile_scene assigned." % owner.name)
		return
	
	var proj = projectile_scene.instantiate() as Projectile
	if not proj:
		push_error("Projectile scene must inherit from Projectile!")
		return

	add_child(proj)
	proj.global_position = attack_point.global_position
	
	# Pass damage payload to projectile's DamageComponent if present
	var dmg_comp = ComponentUtil.get_component(proj, DamageComponent) as DamageComponent
	if dmg_comp:
		dmg_comp.update(damage, damage_type)
	
	## TODO: Set projectile direction/target for seeking projectiles
	proj.target = target
	proj.speed = 300
	
func _deal_direct_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		health.damage(damage, damage_type)
