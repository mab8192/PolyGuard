class_name CameraController extends Camera2D

## Gestures & Controls Configuration
const DRAG_THRESHOLD: float = 8.0
const ZOOM_STEP: float = 1.15
const ZOOM_SMOOTHNESS: float = 18.0
const FIT_PADDING: float = 0.95

## Zoom and Bounds State
var stage_bounds: Rect2 = Rect2()
var fit_zoom: float = 1.0
var min_zoom: float = 1.0
var max_zoom: float = 4.0
var is_placement_active: bool = false

## Smooth Zoom Interpolation
var _target_zoom: float = 1.0
var _zoom_anchor_world: Vector2 = Vector2.ZERO
var _zoom_anchor_screen: Vector2 = Vector2.ZERO
var _is_zooming_smooth: bool = false

## Multi-Touch Tracking (Mobile)
var _touches: Dictionary = {} # int (index) -> Vector2 (position)
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_total_dist: float = 0.0
var _touch_drag_active: bool = false
var _pinch_last_dist: float = 0.0
var _pinch_last_center: Vector2 = Vector2.ZERO
var _last_touch_frame: int = -1

## Mouse Tracking (Desktop)
var _mouse_panning: bool = false
var _mouse_button: int = 0
var _mouse_start_pos: Vector2 = Vector2.ZERO
var _mouse_total_dist: float = 0.0
var _mouse_has_dragged: bool = false

func _ready() -> void:
	SignalBus.placement_mode_changed.connect(_on_placement_mode_changed)

func _process(delta: float) -> void:
	if _is_zooming_smooth:
		var cur_z = zoom.x
		var new_z = lerpf(cur_z, _target_zoom, 1.0 - exp(-ZOOM_SMOOTHNESS * delta))
		if absf(new_z - _target_zoom) < 0.001:
			new_z = _target_zoom
			_is_zooming_smooth = false
		
		zoom = Vector2(new_z, new_z)
		global_position = _zoom_anchor_world - (_zoom_anchor_screen - _get_viewport_center()) / new_z
		_clamp_position()

func _unhandled_input(event: InputEvent) -> void:
	# 1. Screen Touch Events (Mobile)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
			if _touches.size() == 1:
				_touch_start_pos = touch.position
				_touch_total_dist = 0.0
				_touch_drag_active = false
			elif _touches.size() == 2:
				var keys = _touches.keys()
				_pinch_last_dist = _touches[keys[0]].distance_to(_touches[keys[1]])
				_pinch_last_center = (_touches[keys[0]] + _touches[keys[1]]) / 2.0
				_touch_drag_active = true
		else:
			_touches.erase(touch.index)
			if _touches.size() == 1:
				var rem = _touches.keys()[0]
				_touch_start_pos = _touches[rem]
				_touch_total_dist = 0.0
			elif _touches.is_empty():
				if _touch_drag_active:
					_touch_drag_active = false
					get_viewport().set_input_as_handled()
		return

	# 2. Screen Drag Events (Mobile)
	elif event is InputEventScreenDrag:
		_last_touch_frame = Engine.get_process_frames()
		var drag := event as InputEventScreenDrag
		_touches[drag.index] = drag.position
		
		if _touches.size() >= 2:
			_touch_drag_active = true
			var keys = _touches.keys()
			var c_curr: Vector2 = (_touches[keys[0]] + _touches[keys[1]]) / 2.0
			var pan_delta = c_curr - _pinch_last_center
			if not pan_delta.is_zero_approx():
				_pan_by_screen_delta(pan_delta)
			_pinch_last_center = c_curr
			
			var d_curr: float = _touches[keys[0]].distance_to(_touches[keys[1]])
			if _pinch_last_dist > 0.0 and d_curr > 0.0:
				var factor = d_curr / _pinch_last_dist
				_zoom_immediate(zoom.x * factor, c_curr)
				_pinch_last_dist = d_curr
			get_viewport().set_input_as_handled()
			return
		elif _touches.size() == 1:
			if not is_placement_active:
				_touch_total_dist += drag.relative.length()
				if _touch_total_dist >= DRAG_THRESHOLD or _touch_drag_active:
					_touch_drag_active = true
					_pan_by_screen_delta(drag.relative)
					get_viewport().set_input_as_handled()
					return
		return

	# 3. Mouse Button Events (Desktop)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			if mb.pressed and not is_placement_active:
				_zoom_step(ZOOM_STEP, mb.position)
				get_viewport().set_input_as_handled()
				return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed and not is_placement_active:
				_zoom_step(1.0 / ZOOM_STEP, mb.position)
				get_viewport().set_input_as_handled()
				return
		elif mb.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			if mb.pressed:
				_mouse_panning = true
				_mouse_button = mb.button_index
				_mouse_has_dragged = false
			else:
				if _mouse_panning and _mouse_button == mb.button_index:
					_mouse_panning = false
					if _mouse_has_dragged:
						_mouse_has_dragged = false
						get_viewport().set_input_as_handled()
			return
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if not is_placement_active:
					_mouse_panning = true
					_mouse_button = MOUSE_BUTTON_LEFT
					_mouse_start_pos = mb.position
					_mouse_total_dist = 0.0
					_mouse_has_dragged = false
			else:
				if _mouse_panning and _mouse_button == MOUSE_BUTTON_LEFT:
					_mouse_panning = false
					if _mouse_has_dragged:
						_mouse_has_dragged = false
						get_viewport().set_input_as_handled()
			return

	# 4. Mouse Motion Events (Desktop)
	elif event is InputEventMouseMotion:
		if _last_touch_frame == Engine.get_process_frames() and _mouse_button == MOUSE_BUTTON_LEFT:
			return # Skip touch emulation duplicate on same frame
		
		var mm := event as InputEventMouseMotion
		if _mouse_panning:
			if _mouse_button in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
				_mouse_has_dragged = true
				_pan_by_screen_delta(mm.relative)
				get_viewport().set_input_as_handled()
				return
			elif _mouse_button == MOUSE_BUTTON_LEFT and not is_placement_active:
				_mouse_total_dist += mm.relative.length()
				if _mouse_total_dist >= DRAG_THRESHOLD or _mouse_has_dragged:
					_mouse_has_dragged = true
					_pan_by_screen_delta(mm.relative)
					get_viewport().set_input_as_handled()
					return

## Pan the camera by a screen pixel delta
func _pan_by_screen_delta(delta_screen: Vector2) -> void:
	if zoom.x <= 0.0:
		return
	var world_delta = delta_screen / zoom.x
	global_position -= world_delta
	_clamp_position()

## Smooth mouse wheel zoom step anchored at screen position
func _zoom_step(factor: float, screen_pos: Vector2) -> void:
	var next_target = clampf(_target_zoom * factor, min_zoom, max_zoom)
	if is_equal_approx(next_target, _target_zoom) and is_equal_approx(zoom.x, next_target):
		return
	_target_zoom = next_target
	_zoom_anchor_screen = screen_pos
	_zoom_anchor_world = _screen_to_world(screen_pos)
	_is_zooming_smooth = true

## Immediate zoom (for multi-touch pinch gestures) anchored at screen position
func _zoom_immediate(new_zoom_val: float, screen_pos: Vector2) -> void:
	var clamped_z = clampf(new_zoom_val, min_zoom, max_zoom)
	if is_equal_approx(clamped_z, zoom.x):
		return
	var anchor_world = _screen_to_world(screen_pos)
	zoom = Vector2(clamped_z, clamped_z)
	_target_zoom = clamped_z
	_is_zooming_smooth = false
	global_position = anchor_world - (screen_pos - _get_viewport_center()) / clamped_z
	_clamp_position()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return global_position + (screen_pos - _get_viewport_center()) / zoom.x

func _get_viewport_center() -> Vector2:
	return get_viewport_rect().size / 2.0

## Keep camera within stage boundaries (with vertical padding to prevent HUD occlusion)
func _clamp_position() -> void:
	if not stage_bounds.has_area() or zoom.x <= 0.0:
		return
	
	var vp_size = get_viewport_rect().size
	var half_visible = (vp_size / zoom.x) / 2.0
	var v_pad = stage_bounds.size.y * 0.50
	
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
	var min_y: float
	var max_y: float
	if (effective_bottom - effective_top) > half_visible.y * 2.0:
		min_y = effective_top + half_visible.y
		max_y = effective_bottom - half_visible.y
	else:
		var center_y = stage_bounds.get_center().y
		min_y = center_y - v_pad
		max_y = center_y + v_pad

	global_position = Vector2(
		clampf(global_position.x, min_x, max_x),
		clampf(global_position.y, min_y, max_y)
	)

## Public API: Setup camera bounds and fit for a loaded stage
func setup_for_stage(stage: Stage) -> void:
	if not stage:
		return
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

## Reset camera to the default fitted view
func reset_view() -> void:
	zoom = Vector2(fit_zoom, fit_zoom)
	_target_zoom = fit_zoom
	_is_zooming_smooth = false
	if stage_bounds.has_area():
		global_position = stage_bounds.get_center()

## Handle window/viewport size changes
func on_viewport_size_changed() -> void:
	if not stage_bounds.has_area():
		return
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
	if active:
		_touches.clear()
		_touch_drag_active = false
		_mouse_panning = false
		_mouse_has_dragged = false
