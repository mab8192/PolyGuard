class_name HealthComponent extends Node

signal health_changed(health: float)
signal took_damage(dmg: float)
signal healed(amount: float)
signal died()

@export var data: HealthData

const HEALTH_BAR_OFFSET: Vector2 = Vector2(0, -28)
var _died: bool = false
var _health: float
var _health_bar: HealthBarVisualizer = null

## Lightweight 2D canvas item for rendering batched overhead health bars
class HealthBarVisualizer extends Node2D:
	var max_value: float = 100.0:
		set(v):
			max_value = maxf(1.0, v)
			queue_redraw()
	var value: float = 100.0:
		set(v):
			value = v
			queue_redraw()
	var actor: Node2D = null
	var offset: Vector2 = Vector2(0, -28)

	func _ready() -> void:
		z_index = 20
		z_as_relative = false
		set_process(false)
		visible = false

	func _process(_delta: float) -> void:
		if is_instance_valid(actor):
			global_position = actor.global_position + offset
			global_rotation = 0.0
		else:
			queue_free()

	func update_health(cur_hp: float, max_hp: float) -> void:
		value = cur_hp
		max_value = maxf(1.0, max_hp)
		var should_show: bool = (cur_hp < max_hp and cur_hp > 0.0)
		if visible != should_show:
			visible = should_show
			set_process(should_show)
			if should_show and is_instance_valid(actor):
				global_position = actor.global_position + offset
				global_rotation = 0.0
				reset_physics_interpolation()
		if visible:
			queue_redraw()

	func _draw() -> void:
		if max_value <= 0.0 or not visible:
			return
		var ratio: float = clampf(value / max_value, 0.0, 1.0)
		var bar_color: Color
		if ratio > 0.5:
			var t: float = (ratio - 0.5) * 2.0
			bar_color = Color(0.95, 0.8, 0.2).lerp(Color(0.25, 0.85, 0.35), t)
		else:
			var t: float = ratio * 2.0
			bar_color = Color(0.9, 0.25, 0.25).lerp(Color(0.95, 0.8, 0.2), t)

		# Dark background pill
		draw_rect(Rect2(-16.0, -2.0, 32.0, 4.0), Color(0.1, 0.1, 0.15, 0.75))
		# Health fill
		if ratio > 0.0:
			draw_rect(Rect2(-16.0, -2.0, 32.0 * ratio, 4.0), bar_color)


func _ready() -> void:
	if not data:
		push_error("Missing HealthData! %s" % get_path())
	
	if get_parent():
		get_parent().set_meta(&"HealthComponent", self)

	_health = data.max_health if data else 100.0
	
	if data and data.show_health_bar:
		_health_bar = HealthBarVisualizer.new()
		_health_bar.max_value = data.max_health
		_health_bar.value = _health
		_health_bar.offset = HEALTH_BAR_OFFSET
		_health_bar.position = HEALTH_BAR_OFFSET
		
		var actor: Node2D = (owner if owner else get_parent()) as Node2D
		if is_instance_valid(actor):
			_health_bar.actor = actor
			actor.add_child.call_deferred(_health_bar)
	
	health_changed.connect(_on_health_changed)


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
	if not _died and data and _health < data.max_health:
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
		_health_bar.update_health(health, data.max_health if data else health)
