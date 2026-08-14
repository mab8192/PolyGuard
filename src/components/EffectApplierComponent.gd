class_name EffectApplierComponent extends Area2D

signal triggered()
signal deactivated()
signal applied_effect(node: Node2D)
signal removed_effect(node: Node2D)

@export var data: EffectApplierData:
	set(value):
		data = value
		_update_collision_mask()

enum State {IDLE, ARMING, ACTIVE, COOLDOWN}
var _state: State = State.IDLE

var _delay_timer: float = 0.0
var _active_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _enabled: bool = true

## Continuous mode: Node2D -> Array[ActiveEffect]
var _applied_effects: Dictionary = {}

func enable() -> void:
	_enabled = true
	if data and data.mode == EffectApplierData.Mode.CONTINUOUS:
		for body in get_overlapping_bodies():
			_on_body_entered(body)
	else:
		if _state == State.IDLE and _has_valid_overlapping_enemies():
			_start_trigger_sequence()

func disable() -> void:
	_enabled = false
	if data and data.mode == EffectApplierData.Mode.CONTINUOUS:
		for body in get_overlapping_bodies():
			_on_body_exited(body)
	else:
		_state = State.IDLE
		_delay_timer = 0.0
		_active_timer = 0.0
		_cooldown_timer = 0.0

func _ready() -> void:
	if get_parent():
		get_parent().set_meta(&"EffectApplierComponent", self)
	_update_collision_mask()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _update_collision_mask() -> void:
	if data:
		collision_mask = data.targeting_mask

func _process(delta: float) -> void:
	if not _enabled or not data:
		return

	if data.mode == EffectApplierData.Mode.CONTINUOUS:
		return

	match _state:
		State.ARMING:
			_delay_timer -= delta
			if _delay_timer <= 0.0:
				_on_delay_finished()

		State.ACTIVE:
			_active_timer -= delta
			if _active_timer <= 0.0:
				_on_active_phase_finished()

		State.COOLDOWN:
			_cooldown_timer -= delta
			if _cooldown_timer <= 0.0:
				_state = State.IDLE
				if _has_valid_overlapping_enemies():
					_start_trigger_sequence()

func _on_body_entered(body: Node2D) -> void:
	if not _enabled or not data: return
	
	var enemy = body as Enemy
	if not enemy or enemy.is_queued_for_deletion(): return

	match data.mode:
		EffectApplierData.Mode.CONTINUOUS:
			_apply_continuous_effect(enemy)

		EffectApplierData.Mode.BURST:
			if _state == State.IDLE:
				_start_trigger_sequence()

		EffectApplierData.Mode.TRIGGERED_CONTINUOUS:
			if _state == State.IDLE:
				_start_trigger_sequence()
			elif _state == State.ACTIVE:
				_apply_effects_to_enemy(enemy)

func _on_body_exited(body: Node2D) -> void:
	if not _enabled or not data: return

	if data.mode == EffectApplierData.Mode.CONTINUOUS:
		_remove_continuous_effect(body)

func _start_trigger_sequence() -> void:
	if not _enabled or not data: return

	if data.delay > 0.0:
		_state = State.ARMING
		_delay_timer = data.delay
	else:
		_on_delay_finished()

func _on_delay_finished() -> void:
	if data.mode == EffectApplierData.Mode.TRIGGERED_CONTINUOUS:
		_start_active_phase()
	else:
		_trigger_burst()

func _trigger_burst() -> void:
	triggered.emit()

	var enemies = _get_valid_overlapping_enemies()
	for enemy in enemies:
		_apply_effects_to_enemy(enemy)

	_finish_trigger()

func _start_active_phase() -> void:
	triggered.emit()
	_state = State.ACTIVE
	_active_timer = data.active_duration if data.active_duration > 0.0 else 0.1

	var enemies = _get_valid_overlapping_enemies()
	for enemy in enemies:
		_apply_effects_to_enemy(enemy)

func _on_active_phase_finished() -> void:
	deactivated.emit()
	_finish_trigger()

func _finish_trigger() -> void:
	if data.cooldown > 0.0:
		_state = State.COOLDOWN
		_cooldown_timer = data.cooldown
	else:
		_state = State.IDLE
		if _has_valid_overlapping_enemies():
			_start_trigger_sequence()

func _apply_effects_to_enemy(enemy: Enemy) -> void:
	for effect_data in data.effects:
		if not enemy.has_effect(effect_data.name):
			var ac = effect_data.create_instance()
			if ac:
				enemy.apply_effect(ac)
				ac.count_time()
				applied_effect.emit(enemy)

func _apply_continuous_effect(enemy: Enemy) -> void:
	if enemy not in _applied_effects:
		_applied_effects[enemy] = []
		for effect in data.effects:
			var existing_effect = enemy.get_effect(effect.name)
			if existing_effect:
				existing_effect.stop_counting_time()
				_applied_effects[enemy].append(existing_effect)
			else:
				var ac = effect.create_instance()
				if ac:
					enemy.apply_effect(ac)
					_applied_effects[enemy].append(ac)
					applied_effect.emit(enemy)

func _remove_continuous_effect(body: Node2D) -> void:
	for enemy in _applied_effects.keys().duplicate():
		if not is_instance_valid(enemy):
			_applied_effects.erase(enemy)

	if is_instance_valid(body) and body is Enemy and body in _applied_effects:
		for effect in _applied_effects[body]:
			if effect.data and effect.data.remove_on_exit:
				body.remove_effect(effect)
				removed_effect.emit(body)
			else:
				effect.count_time()
			
		_applied_effects.erase(body)

func _get_valid_overlapping_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for body in get_overlapping_bodies():
		if is_instance_valid(body) and body is Enemy and not body.is_queued_for_deletion():
			enemies.append(body as Enemy)
	return enemies

func _has_valid_overlapping_enemies() -> bool:
	for body in get_overlapping_bodies():
		if is_instance_valid(body) and body is Enemy and not body.is_queued_for_deletion():
			return true
	return false
