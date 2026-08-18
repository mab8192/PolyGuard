class_name HealthComponent extends Node

signal health_changed(health: float)
signal took_damage(dmg: float)
signal healed(amount: float)
signal died()

@export var data: HealthData

const HEALTH_BAR_OFFSET: Vector2 = Vector2(0, -28)
var _died: bool = false
var _health: float
var _health_bar: ProgressBar = null
var _fill_stylebox: StyleBoxFlat = null
var _bg_stylebox: StyleBoxFlat = null

func _ready() -> void:
	if not data:
		push_error("Missing HealthData! %s" % get_path())
	
	if get_parent():
		get_parent().set_meta(&"HealthComponent", self)

	_health = data.max_health
	
	if data.show_health_bar:
		_health_bar = ProgressBar.new()
		_health_bar.max_value = data.max_health
		_health_bar.value = _health
		_health_bar.show_percentage = false
		
		_health_bar.custom_minimum_size = Vector2(32, 4)
		_health_bar.custom_maximum_size = Vector2(32, 4)
		_health_bar.top_level = true
		
		_bg_stylebox = StyleBoxFlat.new()
		_bg_stylebox.bg_color = Color(0.1, 0.1, 0.15, 0.75)
		_bg_stylebox.set_corner_radius_all(2)

		_fill_stylebox = StyleBoxFlat.new()
		_fill_stylebox.set_corner_radius_all(2)

		_health_bar.add_theme_stylebox_override("background", _bg_stylebox)
		_health_bar.add_theme_stylebox_override("fill", _fill_stylebox)

		_update_health_bar_color(_health)
		
		# Hide until damaged
		_health_bar.visible = false
		
		owner.add_child.call_deferred(_health_bar)
	
	health_changed.connect(_on_health_changed)

func _process(_delta: float) -> void:
	if _health_bar and _health_bar.visible and is_instance_valid(owner):
		_health_bar.global_position = owner.global_position + HEALTH_BAR_OFFSET - Vector2(16, 2)

func _update_health_bar_color(health: float) -> void:
	if not _fill_stylebox or not data or data.max_health <= 0.0:
		return
	var ratio: float = clampf(health / data.max_health, 0.0, 1.0)
	var bar_color: Color
	if ratio > 0.5:
		# Lerp from Yellow (0.5) to Green (1.0)
		var t: float = (ratio - 0.5) * 2.0
		bar_color = Color(0.95, 0.8, 0.2).lerp(Color(0.25, 0.85, 0.35), t)
	else:
		# Lerp from Red (0.0) to Yellow (0.5)
		var t: float = ratio * 2.0
		bar_color = Color(0.9, 0.25, 0.25).lerp(Color(0.95, 0.8, 0.2), t)
	_fill_stylebox.bg_color = bar_color

## Affects how fast armor scales
const ARMOR_CONSTANT = 50

var _effect_receiver: EffectReceiverComponent
var effect_receiver: EffectReceiverComponent:
	get:
		if _effect_receiver: return _effect_receiver
		var target_node = owner if owner else get_parent()
		if target_node:
			_effect_receiver = ComponentUtil.get_component(target_node, EffectReceiverComponent) as EffectReceiverComponent
		return _effect_receiver

var armor_reduction: float = 0.0
var magic_resistance_reduction: float = 0.0

func get_effective_armor() -> float:
	if not data:
		return 0.0
	var reduction: float = armor_reduction
	if effect_receiver:
		reduction += effect_receiver.get_armor_reduction()
	return maxf(0.0, data.armor - reduction)

func get_effective_magic_resistance() -> float:
	if not data:
		return 0.0
	var reduction: float = magic_resistance_reduction
	if effect_receiver:
		reduction += effect_receiver.get_magic_resistance_reduction()
	return maxf(0.0, data.magic_resistance - reduction)

func damage(amount: float, type: AttackData.DamageType) -> void:
	# Ensures armor doesn't divide by zero or turn negative into health gain
	var damage_multiplier: float = 1.0

	if type == AttackData.DamageType.PHYSICAL:
		var effective_armor: float = get_effective_armor()
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_armor)
	elif type == AttackData.DamageType.MAGIC:
		var effective_resistance: float = get_effective_magic_resistance()
		damage_multiplier = ARMOR_CONSTANT / (ARMOR_CONSTANT + effective_resistance)
	
	var final_damage: float = amount * damage_multiplier
	_health -= final_damage
	took_damage.emit(final_damage)
	health_changed.emit(_health)
	
	if not _died and _health <= 0:
		_died = true
		died.emit()

func heal(amount: float) -> void:
	if not _died and _health < data.max_health:
		_health += amount
		healed.emit(amount)
		_health = min(_health, data.max_health)
		health_changed.emit(_health)

func get_health() -> float:
	return _health

func get_max_health() -> float:
	return data.max_health if data else 0.0

func _on_health_changed(health: float) -> void:
	if _health_bar:
		_health_bar.visible = health < data.max_health
		_health_bar.value = health
		_update_health_bar_color(health)
