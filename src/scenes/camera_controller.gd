class_name CameraController extends Camera2D

## Configuration
const DRAG_THRESHOLD: float = 8.0
const ZOOM_STEP: float = 1.15
const ZOOM_SMOOTHNESS: float = 18.0
const FIT_PADDING: float = 0.95
const PAN_FRICTION: float = 15.0
const MIN_PAN_VELOCITY: float = 15.0
const VERTICAL_PAD_RATIO: float = 0.30

## Stage Bounds & Zoom Limits
var stage_bounds: Rect2 = Rect2()
var fit_zoom: float = 1.0
var min_zoom: float = 1.0
var max_zoom: float = 4.0
var is_placement_active: bool = false

## Unified Pointer Tracking (Touch & Mouse)
var _pointers: Dictionary = {} # pointer_id (int) -> Vector2 (screen position)
var _drag_start_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _pinch_distance: float = 0.0
var _pinch_center: Vector2 = Vector2.ZERO

## Smooth Zoom Interpolation (Mouse Wheel)
var _target_zoom: float = 1.0
var _zoom_anchor_world: Vector2 = Vector2.ZERO
var _zoom_anchor_screen: Vector2 = Vector2.ZERO
var _is_zooming: bool = false

## Momentum Physics
var _velocity: Vector2 = Vector2.ZERO
var _drag_history: Array[Dictionary] = []

func _ready() -> void:
	SignalBus.placement_mode_changed.connect(_on_placement_mode_changed)
	set_process(false)

func _process(delta: float) -> void:
	var still_active: bool = false

	# Smooth mouse wheel zoom interpolation
	if _is_zooming:
		still_active = true
		var cur_z = zoom.x
		var new_z = lerpf(cur_z, _target_zoom, 1.0 - exp(-ZOOM_SMOOTHNESS * delta))
		if absf(new_z - _target_zoom) < 0.001:
			new_z = _target_zoom
			_is_zooming = false
		
		zoom = Vector2(new_z, new_z)
		global_position = _zoom_anchor_world - (_zoom_anchor_screen - _get_viewport_center()) / new_z
		_clamp_position()
	
	# Inertia momentum when released
	if not _is_dragging and _pointers.is_empty() and _velocity.length_squared() > 0.0:
		still_active = true
		global_position -= _velocity * delta
		_clamp_position()
		_velocity = _velocity.lerp(Vector2.ZERO, 1.0 - exp(-PAN_FRICTION * delta))
		if _velocity.length() < (MIN_PAN_VELOCITY / zoom.x):
			_velocity = Vector2.ZERO

	if not still_active:
		set_process(false)

func _unhandled_input(event: InputEvent) -> void:
	# 1. Touch Events (Mobile & Emulated Pointer)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_pointer_down(touch.index, touch.position)
		else:
			if _on_pointer_up(touch.index):
				get_viewport().set_input_as_handled()
		return

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _on_pointer_drag(drag.index, drag.position):
			get_viewport().set_input_as_handled()
		return

	# 2. Mouse Wheel & Middle/Right Drag (Desktop)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed and not is_placement_active:
			_zoom_step(ZOOM_STEP, mb.position)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed and not is_placement_active:
			_zoom_step(1.0 / ZOOM_STEP, mb.position)
			get_viewport().set_input_as_handled()
		elif mb.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			var pointer_id = 100 + mb.button_index
			if mb.pressed:
				_on_pointer_down(pointer_id, mb.position)
			else:
				if _on_pointer_up(pointer_id):
					get_viewport().set_input_as_handled()
		return

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		for btn in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			var pointer_id = 100 + btn
			if _pointers.has(pointer_id):
				if _on_pointer_drag(pointer_id, mm.position):
					get_viewport().set_input_as_handled()
				return

## Pointer Lifecycle Helpers
func _on_pointer_down(id: int, pos: Vector2) -> void:
	_is_zooming = false
	_velocity = Vector2.ZERO
	_drag_history.clear()
	_record_drag_point(pos)
	_pointers[id] = pos
	
	if _pointers.size() == 1:
		_drag_start_pos = pos
		_is_dragging = false
	elif _pointers.size() == 2:
		var keys = _pointers.keys()
		_pinch_distance = _pointers[keys[0]].distance_to(_pointers[keys[1]])
		_pinch_center = (_pointers[keys[0]] + _pointers[keys[1]]) / 2.0
		_is_dragging = true

func _on_pointer_drag(id: int, pos: Vector2) -> bool:
	if not _pointers.has(id):
		_pointers[id] = pos
		return false
	
	if _pointers.size() >= 2:
		_pointers[id] = pos
		_is_dragging = true
		var keys = _pointers.keys()
		var p0: Vector2 = _pointers[keys[0]]
		var p1: Vector2 = _pointers[keys[1]]
		var new_center = (p0 + p1) / 2.0
		var new_dist = p0.distance_to(p1)
		
		_record_drag_point(new_center)
		
		# Two-finger pan
		var pan_delta = new_center - _pinch_center
		if not pan_delta.is_zero_approx():
			_pan_by_screen_delta(pan_delta)
		_pinch_center = new_center
		
		# Two-finger pinch zoom
		if _pinch_distance > 0.0 and new_dist > 0.0:
			var factor = new_dist / _pinch_distance
			_zoom_immediate(zoom.x * factor, new_center)
			_pinch_distance = new_dist
		return true
		
	elif _pointers.size() == 1:
		if is_placement_active:
			_pointers[id] = pos
			return false
		
		var prev_pos: Vector2 = _pointers[id]
		var delta_pos: Vector2 = pos - prev_pos
		_pointers[id] = pos
		_record_drag_point(pos)
		
		if pos.distance_to(_drag_start_pos) >= DRAG_THRESHOLD or _is_dragging:
			_is_dragging = true
			_pan_by_screen_delta(delta_pos)
			return true
	
	return false

func _on_pointer_up(id: int) -> bool:
	_pointers.erase(id)
	
	if _pointers.size() == 1:
		var rem_id = _pointers.keys()[0]
		_drag_start_pos = _pointers[rem_id]
		_drag_history.clear()
		_record_drag_point(_pointers[rem_id])
		return _is_dragging
		
	elif _pointers.is_empty():
		if _is_dragging:
			_is_dragging = false
			_velocity = _calculate_release_velocity() / zoom.x
			if _velocity.length_squared() > 0.0:
				set_process(true)
			return true
			
	return false

## Pan & Zoom Operations
func _pan_by_screen_delta(delta_screen: Vector2) -> void:
	if zoom.x <= 0.0:
		return
	global_position -= delta_screen / zoom.x
	_clamp_position()

func _zoom_step(factor: float, screen_pos: Vector2) -> void:
	var next_target = clampf(_target_zoom * factor, min_zoom, max_zoom)
	if is_equal_approx(next_target, _target_zoom) and is_equal_approx(zoom.x, next_target):
		return
	_target_zoom = next_target
	_zoom_anchor_screen = screen_pos
	_zoom_anchor_world = _screen_to_world(screen_pos)
	_is_zooming = true
	set_process(true)

func _zoom_immediate(new_zoom_val: float, screen_pos: Vector2) -> void:
	var clamped_z = clampf(new_zoom_val, min_zoom, max_zoom)
	if is_equal_approx(clamped_z, zoom.x):
		return
	var anchor_world = _screen_to_world(screen_pos)
	zoom = Vector2(clamped_z, clamped_z)
	_target_zoom = clamped_z
	_is_zooming = false
	global_position = anchor_world - (screen_pos - _get_viewport_center()) / clamped_z
	_clamp_position()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return global_position + (screen_pos - _get_viewport_center()) / zoom.x

func _get_viewport_center() -> Vector2:
	return get_viewport_rect().size / 2.0

## Bounds Clamping with Vertical HUD Margin
func _clamp_position() -> void:
	if not stage_bounds.has_area() or zoom.x <= 0.0:
		return
	
	var vp_size = get_viewport_rect().size
	var half_visible = (vp_size / zoom.x) / 2.0
	var v_pad = stage_bounds.size.y * VERTICAL_PAD_RATIO
	
	var min_x: float
	var max_x: float
	if stage_bounds.size.x > half_visible.x * 2.0:
		min_x = stage_bounds.position.x + half_visible.x
		max_x = stage_bounds.end.x - half_visible.x
	else:
		var center_x = stage_bounds.get_center().x
		min_x = center_x
		max_x = center_x

	var effective_top = stage_bounds.position.y - v_pad
	var effective_bottom = stage_bounds.end.y + v_pad
	var effective_height = effective_bottom - effective_top
	var min_y: float
	var max_y: float
	if effective_height > half_visible.y * 2.0:
		min_y = effective_top + half_visible.y
		max_y = effective_bottom - half_visible.y
	else:
		var center_y = stage_bounds.get_center().y
		min_y = center_y
		max_y = center_y

	global_position = Vector2(
		clampf(global_position.x, min_x, max_x),
		clampf(global_position.y, min_y, max_y)
	)

## Stage Lifecycle API
func setup_for_stage(stage: Stage) -> void:
	if not stage:
		return
	_clear_motion_state()
	stage_bounds = stage.get_map_pixel_rect()
	_recalculate_zoom_limits()
	reset_view()

func _recalculate_zoom_limits() -> void:
	if not stage_bounds.has_area():
		return
	var vp_size = get_viewport_rect().size
	var zoom_x = (vp_size.x * FIT_PADDING) / stage_bounds.size.x
	var zoom_y = (vp_size.y * FIT_PADDING) / stage_bounds.size.y
	fit_zoom = minf(zoom_x, zoom_y)
	min_zoom = fit_zoom
	max_zoom = maxf(fit_zoom * 3.5, 4.0)

func reset_view() -> void:
	_clear_motion_state()
	zoom = Vector2(fit_zoom, fit_zoom)
	_target_zoom = fit_zoom
	_is_zooming = false
	if stage_bounds.has_area():
		global_position = stage_bounds.get_center()

func on_viewport_size_changed() -> void:
	if not stage_bounds.has_area():
		return
	_clear_motion_state()
	var old_fit = fit_zoom
	_recalculate_zoom_limits()
	if is_equal_approx(zoom.x, old_fit):
		reset_view()
	else:
		_target_zoom = clampf(_target_zoom, min_zoom, max_zoom)
		var new_z = clampf(zoom.x, min_zoom, max_zoom)
		zoom = Vector2(new_z, new_z)
		_clamp_position()

func _on_placement_mode_changed(active: bool) -> void:
	is_placement_active = active
	_clear_motion_state()

func _clear_motion_state() -> void:
	_velocity = Vector2.ZERO
	_drag_history.clear()
	_pointers.clear()
	_is_dragging = false

## Velocity & Momentum Helpers
func _record_drag_point(screen_pos: Vector2) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	_drag_history.append({"pos": screen_pos, "time": now})
	while _drag_history.size() > 6:
		_drag_history.pop_front()

func _calculate_release_velocity() -> Vector2:
	if _drag_history.size() < 2:
		return Vector2.ZERO
	var now = Time.get_ticks_msec() / 1000.0
	var newest = _drag_history.back()
	if now - newest["time"] > 0.08:
		return Vector2.ZERO
	
	var oldest = _drag_history[0]
	for i in range(_drag_history.size() - 2, -1, -1):
		if newest["time"] - _drag_history[i]["time"] <= 0.15:
			oldest = _drag_history[i]
		else:
			break
			
	var dt = newest["time"] - oldest["time"]
	if dt > 0.001 and dt <= 0.20:
		var dpos: Vector2 = newest["pos"] - oldest["pos"]
		return (dpos / dt).limit_length(3500.0)
	return Vector2.ZERO
