class_name DamageComponent extends Area2D

signal hit(target: Node2D)

var damage: float = 10.0
var damage_type: AttackComponent.DamageType = AttackComponent.DamageType.PHYSICAL:
	set(val):
		damage_type = val
		_update_collision_mask()

var can_target_physical: bool = true:
	set(val):
		can_target_physical = val
		_update_collision_mask()

var can_target_ghost: bool = false:
	set(val):
		can_target_ghost = val
		_update_collision_mask()

func update(amount: float, type: AttackComponent.DamageType) -> void:
	damage = amount
	damage_type = type

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_collision_mask()

func _update_collision_mask() -> void:
	var mask: int = 0
	if can_target_physical:
		mask |= 4 # Physics Layer 3 (Physical Enemies)
	if can_target_ghost or damage_type == AttackComponent.DamageType.MAGIC or damage_type == AttackComponent.DamageType.TRUE:
		mask |= 8 # Physics Layer 4 (Ghost Enemies)
	collision_mask = mask

func _on_body_entered(body: Node2D) -> void:
	_try_deal_damage(body)
	hit.emit(body)

func _try_deal_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		health.damage(damage, damage_type)
