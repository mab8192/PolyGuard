class_name HealthComponent extends Node

signal health_changed(health: float)
signal died()

@export var data: HealthData

const HEALTH_BAR_OFFSET: Vector2 = Vector2(0, -28)
var _health_bar: ProgressBar = null
var _health: float

func _ready() -> void:
	if not data:
		push_error("Missing HealthData! %s" % get_path())
	
	if get_parent():
		get_parent().set_meta(&"HealthComponent", self)

	_health = data.max_health
	
	if data.show_health_bar:
		print("HEALTH BAR")
		_health_bar = ProgressBar.new()
		_health_bar.max_value = data.max_health
		_health_bar.value = _health
		_health_bar.show_percentage = false
		
		_health_bar.custom_minimum_size = Vector2(32, 4)
		_health_bar.custom_maximum_size = Vector2(32, 4)
		_health_bar.position = HEALTH_BAR_OFFSET - Vector2(16, 2)
		
		# Hide until damaged
		_health_bar.visible = false
		
		owner.add_child.call_deferred(_health_bar)
	
	health_changed.connect(_on_health_changed)

## Affects how fast armor scales
const ARMOR_CONSTANT = 50

func damage(amount: float, type: AttackComponent.DamageType) -> void:
	# Ensures armor doesn't divide by zero or turn negative into health gain
	var damage_multiplier: float = 1.0

	if type == AttackComponent.DamageType.PHYSICAL:
		var effective_armor: float = max(0.0, data.armor)
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_armor)
	elif type == AttackComponent.DamageType.MAGIC:
		var effective_resistance: float = max(0.0, data.magic_resistance)
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_resistance)
	
	var final_damage: float = amount * damage_multiplier
	_health -= final_damage
	
	health_changed.emit(_health)
	
	if _health <= 0:
		died.emit()

func heal(amount: float) -> void:
	if _health < data.max_health:
		_health += amount
		_health = min(_health, data.max_health)
		health_changed.emit(_health)

func get_health() -> float:
	return _health

func _on_health_changed(health: float) -> void:
	print("Helath canged, ", health)
	_health_bar.visible = health < data.max_health
	_health_bar.value = health
