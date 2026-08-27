class_name EffectApplierComponent extends Area2D

signal triggered()
signal deactivated()
signal cooldown_started()
signal cooldown_finished()
signal applied_effect(node: Node2D)
signal removed_effect(node: Node2D)

@export var data: EffectApplierData:
	set(value):
		data = value
		_update_collision_mask()

const RANGE_BORDER_COLOR: Color = Color(0.0, 0.96, 0.83, 0.95)
const RANGE_FILL_COLOR: Color = Color(0.0, 0.96, 0.83, 0.12)
const RANGE_BORDER_WIDTH: float = 2.5

const BLOCKED_RANGE_FILL_COLOR: Color = Color(1.0, 0.18, 0.18, 0.15)
const BLOCKED_RANGE_BORDER_COLOR: Color = Color(1.0, 0.25, 0.25, 0.85)

var is_range_visible: bool = false:
	set(value):
		if is_range_visible != value:
			is_range_visible = value
			queue_redraw()

var _last_range_pos: Vector2 = Vector2.INF
var _last_range_rot: float = INF

enum State {IDLE, ARMING, ACTIVE, COOLDOWN}
var _state: State = State.IDLE

var _delay_timer: float = 0.0
var _active_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _application_count: int = 0
var _enabled: bool = true

## Continuous mode: Node2D -> Array[ActiveEffect]
var _applied_effects: Dictionary = {}

func enable() -> void:
	_enabled = true
	if _state != State.COOLDOWN:
		if data and data.mode == EffectApplierData.Mode.CONTINUOUS:
			for body in get_overlapping_bodies():
				_on_body_entered(body)
		else:
			if _state == State.IDLE and _has_valid_overlapping_receivers():
				_start_trigger_sequence()

func disable() -> void:
	_enabled = false
	_application_count = 0
	if data and data.mode == EffectApplierData.Mode.CONTINUOUS:
		for body in get_overlapping_bodies():
			_remove_continuous_effect(body)
	else:
		_state = State.IDLE
		_delay_timer = 0.0
		_active_timer = 0.0
		_cooldown_timer = 0.0

func _exit_tree() -> void:
	for body in _applied_effects.keys().duplicate():
		_remove_continuous_effect(body)
	_applied_effects.clear()

func _ready() -> void:
	z_index = 12
	z_as_relative = false

	if get_parent():
		get_parent().set_meta(&"EffectApplierComponent", self)
	_update_collision_mask()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _update_collision_mask() -> void:
	if data:
		collision_mask = data.targeting_mask

func _process(delta: float) -> void:
	if is_range_visible:
		var cur_pos := global_position
		var cur_rot := global_rotation
		if cur_pos != _last_range_pos or cur_rot != _last_range_rot:
			_last_range_pos = cur_pos
			_last_range_rot = cur_rot
			queue_redraw()

	if not _enabled or not data:
		return

	match _state:
		State.ARMING:
			if data.mode != EffectApplierData.Mode.CONTINUOUS:
				_delay_timer -= delta
				if _delay_timer <= 0.0:
					_on_delay_finished()

		State.ACTIVE:
			if data.mode != EffectApplierData.Mode.CONTINUOUS:
				_active_timer -= delta
				if _active_timer <= 0.0:
					_on_active_phase_finished()

		State.COOLDOWN:
			_cooldown_timer -= delta
			if _cooldown_timer <= 0.0:
				_state = State.IDLE
				_application_count = 0
				cooldown_finished.emit()
				
				# Re-evaluate overlapping bodies
				if data.mode == EffectApplierData.Mode.CONTINUOUS:
					for body in get_overlapping_bodies():
						_on_body_entered(body)
				else:
					if _has_valid_overlapping_receivers():
						_start_trigger_sequence()

func _on_body_entered(body: Node2D) -> void:
	if not _enabled or not data or _state == State.COOLDOWN:
		return
	
	if not _is_valid_target(body):
		return

	var receiver = ComponentUtil.get_component(body, EffectReceiverComponent) as EffectReceiverComponent
	if not receiver:
		return

	match data.mode:
		EffectApplierData.Mode.CONTINUOUS:
			_apply_continuous_effect(receiver, body)
			_application_count += 1
			if data.max_targets > 0 and _application_count >= data.max_targets:
				_start_continuous_cooldown()

		EffectApplierData.Mode.BURST:
			if _state == State.IDLE:
				_start_trigger_sequence()

		EffectApplierData.Mode.TRIGGERED_CONTINUOUS:
			if _state == State.IDLE:
				_start_trigger_sequence()
			elif _state == State.ACTIVE:
				_apply_effects_to_target(receiver, body)

func _on_body_exited(body: Node2D) -> void:
	if not _enabled or not data:
		return

	if data.mode == EffectApplierData.Mode.CONTINUOUS:
		_remove_continuous_effect(body)

func _start_continuous_cooldown() -> void:
	for body in get_overlapping_bodies():
		_remove_continuous_effect(body)
	
	if data.cooldown > 0.0:
		_state = State.COOLDOWN
		_cooldown_timer = data.cooldown
		cooldown_started.emit()
	else:
		_state = State.IDLE
		_application_count = 0

func _start_trigger_sequence() -> void:
	if not _enabled or not data:
		return

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

	var targets = _get_valid_overlapping_targets()
	for target in targets:
		_apply_effects_to_target(target.receiver, target.body)
		_application_count += 1
		if data.max_targets > 0 and _application_count >= data.max_targets:
			break

	_finish_trigger()

func _start_active_phase() -> void:
	triggered.emit()
	_state = State.ACTIVE
	_active_timer = data.active_duration if data.active_duration > 0.0 else 0.1

	var targets = _get_valid_overlapping_targets()
	for target in targets:
		_apply_effects_to_target(target.receiver, target.body)

func _on_active_phase_finished() -> void:
	deactivated.emit()
	_finish_trigger()

func _finish_trigger() -> void:
	if data.cooldown > 0.0:
		_state = State.COOLDOWN
		_cooldown_timer = data.cooldown
		cooldown_started.emit()
	else:
		_state = State.IDLE
		_application_count = 0
		if _has_valid_overlapping_receivers():
			_start_trigger_sequence()

func _apply_effects_to_target(receiver: EffectReceiverComponent, body: Node2D) -> void:
	for effect_data in data.effects:
		var existing = receiver.get_effect(effect_data.name)
		if existing:
			existing.add_source(self)
			existing.count_time()
		else:
			var ac = effect_data.create_instance()
			if ac:
				ac.add_source(self)
				receiver.apply_effect(ac)
				ac.count_time()
				applied_effect.emit(body)

func _apply_continuous_effect(receiver: EffectReceiverComponent, body: Node2D) -> void:
	if body not in _applied_effects:
		_applied_effects[body] = []
	
	for effect_data in data.effects:
		var existing_effect = receiver.get_effect(effect_data.name)
		if existing_effect:
			existing_effect.add_source(self)
			existing_effect.stop_counting_time()
			if existing_effect not in _applied_effects[body]:
				_applied_effects[body].append(existing_effect)
		else:
			var ac = effect_data.create_instance()
			if ac:
				ac.add_source(self)
				receiver.apply_effect(ac)
				if ac not in _applied_effects[body]:
					_applied_effects[body].append(ac)
				applied_effect.emit(body)

func _remove_continuous_effect(body: Node2D) -> void:
	for b in _applied_effects.keys().duplicate():
		if not is_instance_valid(b):
			_applied_effects.erase(b)

	if is_instance_valid(body) and body in _applied_effects:
		var receiver = ComponentUtil.get_component(body, EffectReceiverComponent) as EffectReceiverComponent
		for effect in _applied_effects[body]:
			effect.remove_source(self)
			if not effect.has_active_sources():
				if effect.data.remove_on_exit:
					if receiver:
						receiver.remove_effect(effect)
					removed_effect.emit(body)
				else:
					effect.count_time()
			else:
				effect.stop_counting_time()
			
		_applied_effects.erase(body)

func get_targeting_origin_global() -> Vector2:
	return RangeVisualizer.get_targeting_origin_global(self)

func _has_line_of_sight(target: Node2D) -> bool:
	return RangeVisualizer.has_line_of_sight(get_targeting_origin_global(), target, self)

func _is_valid_target(body: Node2D) -> bool:
	if not is_instance_valid(body) or body.is_queued_for_deletion():
		return false
	if data and not data.can_target_self:
		if body == get_parent() or body == owner:
			return false
	if data and not data.can_target_through_walls:
		if not _has_line_of_sight(body):
			return false
	return true

func _get_valid_overlapping_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for body in get_overlapping_bodies():
		if _is_valid_target(body):
			var receiver = ComponentUtil.get_component(body, EffectReceiverComponent) as EffectReceiverComponent
			if receiver:
				targets.append({"body": body, "receiver": receiver})
	return targets

func _has_valid_overlapping_receivers() -> bool:
	for body in get_overlapping_bodies():
		if _is_valid_target(body):
			if ComponentUtil.get_component(body, EffectReceiverComponent):
				return true
	return false

func _draw() -> void:
	if not is_range_visible:
		return
	var can_apply_through := data != null and data.can_target_through_walls
	RangeVisualizer.draw_range(self, can_apply_through)
