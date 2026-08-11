class_name AttackData extends Resource

@export var damage: float = 50.0
@export var damage_type: AttackComponent.DamageType = AttackComponent.DamageType.PHYSICAL
@export var attack_mode: AttackComponent.AttackMode = AttackComponent.AttackMode.PROJECTILE
@export var cooldown: float = 500.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
