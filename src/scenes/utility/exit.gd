class_name Exit
extends Area2D

signal state_changed(is_active: bool)

enum IndicatorState { NONE, ACTIVE, WILL_ACTIVATE }

@export_group("Configuration")
## Optional unique ID for wave targeting. Defaults to node name if left empty.
@export var exit_id: String = ""
## Whether this exit is active and counts as a valid goal for enemies.
const ACTIVE_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_MODULATE: Color = Color(0.48, 0.48, 0.54, 0.75)

@export var is_active: bool = true:
	set(val):
		var changed = (is_active != val)
		is_active = val
		_update_state(changed and is_inside_tree())
		state_changed.emit(val)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var indicator_state: IndicatorState = IndicatorState.NONE
var _indicator_node: Node2D = null
var _pulse_tween: Tween = null
var _highlight_tween: Tween = null

func get_global_rect() -> Rect2:
	if collision_shape_2d and collision_shape_2d.shape:
		var s = collision_shape_2d.shape
		if s is RectangleShape2D:
			return Rect2(collision_shape_2d.global_position - s.size / 2.0, s.size)
		elif s is CircleShape2D:
			return Rect2(collision_shape_2d.global_position - Vector2(s.radius, s.radius), Vector2(s.radius * 2.0, s.radius * 2.0))
	return Rect2(global_position - Vector2(16.0, 16.0), Vector2(32.0, 32.0))

func _ready() -> void:
	if exit_id.is_empty():
		exit_id = name
	_update_state(false)
	_update_indicator_ui()

func activate(animate: bool = true) -> void:
	var was_inactive = !is_active
	is_active = true
	if was_inactive and animate:
		play_activation_animation()
	SignalBus.exits_updated.emit()

func deactivate() -> void:
	is_active = false
	SignalBus.exits_updated.emit()

func set_active(val: bool, animate: bool = true) -> void:
	if val:
		activate(animate)
	else:
		deactivate()

func play_activation_animation() -> void:
	if not is_inside_tree():
		return
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()

	_highlight_tween = create_tween()
	modulate = Color(1.8, 2.5, 2.5, 1.0)
	scale = Vector2(1.25, 1.25)
	_highlight_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_highlight_tween.parallel().tween_property(self, "modulate", Color(0.3, 0.8, 0.8, 0.9), 0.2)
	_highlight_tween.tween_property(self, "modulate", Color(1.6, 2.2, 2.2, 1.0), 0.2)
	_highlight_tween.tween_property(self, "modulate", ACTIVE_MODULATE, 0.4)

func set_indicator(state: IndicatorState) -> void:
	if indicator_state == state:
		return
	indicator_state = state
	_update_indicator_ui()

func _update_indicator_ui() -> void:
	if not is_inside_tree():
		return

	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if indicator_state == IndicatorState.NONE:
		if _indicator_node:
			_indicator_node.queue_free()
			_indicator_node = null
		return

	if not _indicator_node:
		_indicator_node = Node2D.new()
		_indicator_node.name = "WaveIndicator"
		_indicator_node.position = Vector2(0, -46)
		add_child(_indicator_node)

	for child in _indicator_node.get_children():
		child.queue_free()

	var badge_panel = PanelContainer.new()
	badge_panel.theme = preload("res://src/misc/theme.tres")
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if indicator_state == IndicatorState.WILL_ACTIVATE:
		badge_panel.theme_type_variation = &"ActivatingBadge"
		label.theme_type_variation = &"ActivatingText"
		label.text = "ACTIVATING"
	elif indicator_state == IndicatorState.ACTIVE:
		badge_panel.theme_type_variation = &"ExitBadge"
		label.theme_type_variation = &"ExitText"
		label.text = "EXIT"

	badge_panel.add_child(label)
	_indicator_node.add_child(badge_panel)

	# Dynamic centering of badge around (0, 0)
	badge_panel.reset_size()
	var sz = badge_panel.get_combined_minimum_size()
	badge_panel.position = -sz / 2.0

	# Pulse animation
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_indicator_node, "scale", Vector2(1.1, 1.1), 0.45).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_indicator_node, "scale", Vector2(0.95, 0.95), 0.45).set_trans(Tween.TRANS_SINE)

func matches_id(id_or_name: String) -> bool:
	return exit_id == id_or_name or name == id_or_name

func _update_state(animate: bool = false) -> void:
	if not is_inside_tree():
		return
	var target_col = ACTIVE_MODULATE if is_active else INACTIVE_MODULATE
	if animate:
		var tween = create_tween()
		tween.tween_property(self, "modulate", target_col, 0.4)
	else:
		modulate = target_col
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", !is_active)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
		
	var enemy: Enemy = body as Enemy
	if enemy == null or enemy.is_queued_for_deletion():
		return
	
	enemy.queue_free()
	SignalBus.enemy_exit.emit(enemy)
