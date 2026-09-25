class_name AttackData extends Resource

enum DamageType { PHYSICAL, MAGIC, TRUE }
enum AttackMode { PROJECTILE, MELEE, CONTINUOUS }

@export var damage: float = 50.0 ## Base damage dealt per attack hit or damage tick
@export var damage_type: DamageType = DamageType.PHYSICAL ## Type of damage dealt (affects armor and magic resistance reductions)
@export var attack_mode: AttackMode = AttackMode.PROJECTILE ## Mode of delivering attacks (projectile, melee strike, or continuous beam/area)
@export var cooldown: float = 0.5 ## Time in seconds between consecutive attacks
@export var initial_delay: float = 0.0 ## Seconds to aim after acquiring a target before the first shot (0 = fire immediately)

@export_group("Projectile Settings", "projectile_")
@export var projectile_scene: PackedScene ## PackedScene for the projectile instance to spawn when attacking
@export var projectile_speed: float = 400.0 ## Flight speed of the spawned projectile in pixels per second
@export var projectile_follow_target: bool = true ## If true, projectile tracks target; if false, travels in a fixed initial direction
