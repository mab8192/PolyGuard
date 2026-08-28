class_name DragScrollContainer extends ScrollContainer

const DRAG_THRESHOLD: float = 8.0
const FRICTION: float = 0.90
const MIN_VELOCITY: float = 10.0

var _is_pointer_down: bool = false
var _pointer_start_pos: Vector2 = Vector2.ZERO
var _pointer_last_pos: Vector2 = Vector2.ZERO
var _drag_active: bool = false
var _velocity_y: float = 0.0
var _velocity_x: float = 0.0
var _history: Array[Dictionary] = []

static var is_globally_dragging: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if vertical_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
		vertical_scroll_mode = ScrollMode.SCROLL_MODE_SHOW_NEVER
	if horizontal_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
		horizontal_scroll_mode = ScrollMode.SCROLL_MODE_SHOW_NEVER

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not is_visible_in_tree():
			_reset_drag_state_immediate()

func _process(delta: float) -> void:
	if not _is_pointer_down and (absf(_velocity_y) > MIN_VELOCITY or absf(_velocity_x) > MIN_VELOCITY):
		if vertical_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
			var prev_v = scroll_vertical
			scroll_vertical -= int(_velocity_y * delta)
			if scroll_vertical == prev_v:
				_velocity_y = 0.0
				
		if horizontal_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
			var prev_h = scroll_horizontal
			scroll_horizontal -= int(_velocity_x * delta)
			if scroll_horizontal == prev_h:
				_velocity_x = 0.0
		
		_velocity_y *= pow(FRICTION, delta * 60.0)
		_velocity_x *= pow(FRICTION, delta * 60.0)
		
		if absf(_velocity_y) <= MIN_VELOCITY:
			_velocity_y = 0.0
		if absf(_velocity_x) <= MIN_VELOCITY:
			_velocity_x = 0.0

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		if _is_pointer_down:
			_reset_drag_state_immediate()
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _can_capture_pointer(mb.global_position):
					_start_pointer(mb.global_position)
			else:
				if _is_pointer_down:
					_end_pointer()

	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _can_capture_pointer(st.position):
				_start_pointer(st.position)
		else:
			if _is_pointer_down:
				_end_pointer()

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_pointer_down:
			_handle_pointer_motion(mm.global_position)

	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _is_pointer_down:
			_handle_pointer_motion(sd.position)

func _can_capture_pointer(pos: Vector2) -> bool:
	if not is_visible_in_tree():
		return false
	if not get_global_rect().has_point(pos):
		return false
	
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered != null:
		if hovered != self and not is_ancestor_of(hovered):
			return false
	
	if _is_blocked_by_higher_canvas_layer(pos):
		return false
	
	return true

func _get_canvas_layer() -> int:
	var p := get_parent()
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0

func _is_blocked_by_higher_canvas_layer(pos: Vector2) -> bool:
	var my_layer := _get_canvas_layer()
	var root := get_tree().root
	if root == null:
		return false
	return _check_higher_canvas_layer(root, my_layer, pos)

func _check_higher_canvas_layer(node: Node, my_layer: int, pos: Vector2) -> bool:
	if node is CanvasLayer:
		var cl := node as CanvasLayer
		if cl.visible and cl.layer > my_layer:
			if _has_interactive_control_at(cl, pos):
				return true
	for child in node.get_children():
		if _check_higher_canvas_layer(child, my_layer, pos):
			return true
	return false

func _has_interactive_control_at(node: Node, pos: Vector2) -> bool:
	if node is Control:
		var ctrl := node as Control
		if ctrl.is_visible_in_tree() and ctrl.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			if ctrl.get_global_rect().has_point(pos):
				return true
	for child in node.get_children():
		if not (child is CanvasLayer):
			if _has_interactive_control_at(child, pos):
				return true
	return false

func _start_pointer(pos: Vector2) -> void:
	_is_pointer_down = true
	_drag_active = false
	_pointer_start_pos = pos
	_pointer_last_pos = pos
	_velocity_y = 0.0
	_velocity_x = 0.0
	_history.clear()
	_history.append({"pos": pos, "time": Time.get_ticks_msec() / 1000.0})

func _end_pointer() -> void:
	_is_pointer_down = false
	if _drag_active:
		_calculate_release_velocity()
	call_deferred(&"_reset_drag_state")

func _handle_pointer_motion(pos: Vector2) -> void:
	var total_dist = pos.distance_to(_pointer_start_pos)
	
	if not _drag_active and total_dist >= DRAG_THRESHOLD:
		_drag_active = true
		is_globally_dragging = true
	
	if _drag_active:
		var delta_pos = pos - _pointer_last_pos
		_pointer_last_pos = pos
		
		if vertical_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
			scroll_vertical -= int(delta_pos.y)
		if horizontal_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
			scroll_horizontal -= int(delta_pos.x)
		
		var now = Time.get_ticks_msec() / 1000.0
		_history.append({"pos": pos, "time": now})
		while _history.size() > 5:
			_history.pop_front()
		
		get_viewport().set_input_as_handled()

func _calculate_release_velocity() -> void:
	if _history.size() < 2:
		return
	var oldest = _history[0]
	var newest = _history.back()
	var dt = newest["time"] - oldest["time"]
	if dt > 0.001 and dt < 0.25:
		var dpos: Vector2 = newest["pos"] - oldest["pos"]
		_velocity_y = dpos.y / dt
		_velocity_x = dpos.x / dt

func _reset_drag_state() -> void:
	_drag_active = false
	is_globally_dragging = false

func _reset_drag_state_immediate() -> void:
	_is_pointer_down = false
	_drag_active = false
	is_globally_dragging = false
