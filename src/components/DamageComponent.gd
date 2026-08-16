class_name DamageComponent extends Area2D

signal hit(target: Node2D)

var damage: float
var damage_type: AttackData.DamageType:
	set(val):
		damage_type = val
		_update_collision_mask()

var targeting_mask: int = 4:
	set(val):
		targeting_mask = val
		_update_collision_mask()

var piercing: bool = false
var _hit_something: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_collision_mask()

func _update_collision_mask() -> void:
	var mask: int = targeting_mask
	if damage_type == AttackData.DamageType.MAGIC or damage_type == AttackData.DamageType.TRUE:
		mask |= 8 # Physics Layer 4 (Ghost Enemies)
	collision_mask = mask

func _on_body_entered(body: Node2D) -> void:
	if piercing or not _hit_something:
		_try_deal_damage(body)
		hit.emit(body)
		_hit_something = true

func _try_deal_damage(target: Node2D) -> void:
	var health = ComponentUtil.get_component(target, HealthComponent) as HealthComponent
	if health:
		health.damage(damage, damage_type)
