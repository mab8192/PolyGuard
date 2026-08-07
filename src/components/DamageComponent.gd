class_name DamageComponent extends Area2D

signal hit(target: Node2D)

@export var damage_amount: float = 10.0
@export var damage_type: AttackComponent.DamageType = AttackComponent.DamageType.PHYSICAL

func update(amount: float, type: AttackComponent.DamageType) -> void:
	damage_amount = amount
	damage_type = type

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if damage_type == AttackComponent.DamageType.PHYSICAL:
		collision_mask = 4  ## Physical damage only hits physical enemies
	elif damage_type == AttackComponent.DamageType.MAGIC:
		collision_mask = 12  ## Magic damage hits both kinds of enemies
	elif damage_type == AttackComponent.DamageType.TRUE:
		collision_mask = 12  ## True damage hits both kinds of enemies

func _on_body_entered(body: Node2D) -> void:
	_try_deal_damage(body)
	hit.emit(body)

func _try_deal_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		health.damage(damage_amount, damage_type)
