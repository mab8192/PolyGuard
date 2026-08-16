class_name AttackData extends Resource

enum DamageType { PHYSICAL, MAGIC, TRUE }
enum AttackMode { PROJECTILE, MELEE, CONTINUOUS }

@export var damage: float = 50.0
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var attack_mode: AttackMode = AttackMode.PROJECTILE
@export var cooldown: float = 0.5

@export_group("Projectile Settings", "projectile_")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var projectile_follow_target: bool = true
