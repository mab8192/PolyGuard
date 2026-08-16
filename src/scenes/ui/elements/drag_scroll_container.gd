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
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var inside = get_global_rect().has_point(mb.global_position)
			if mb.pressed:
				if inside:
					_is_pointer_down = true
					_drag_active = false
					_pointer_start_pos = mb.global_position
					_pointer_last_pos = mb.global_position
					_velocity_y = 0.0
					_velocity_x = 0.0
					_history.clear()
					_history.append({"pos": mb.global_position, "time": Time.get_ticks_msec() / 1000.0})
			else:
				if _is_pointer_down:
					_is_pointer_down = false
					if _drag_active:
						_calculate_release_velocity()
					call_deferred(&"_reset_drag_state")

	elif event is InputEventMouseMotion and _is_pointer_down:
		var mm := event as InputEventMouseMotion
		var total_dist = mm.global_position.distance_to(_pointer_start_pos)
		
		if not _drag_active and total_dist >= DRAG_THRESHOLD:
			_drag_active = true
			is_globally_dragging = true
		
		if _drag_active:
			var delta_pos = mm.global_position - _pointer_last_pos
			_pointer_last_pos = mm.global_position
			
			if vertical_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
				scroll_vertical -= int(delta_pos.y)
			if horizontal_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
				scroll_horizontal -= int(delta_pos.x)
			
			var now = Time.get_ticks_msec() / 1000.0
			_history.append({"pos": mm.global_position, "time": now})
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
