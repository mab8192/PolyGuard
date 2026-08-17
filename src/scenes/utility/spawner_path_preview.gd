class_name SpawnerPathPreview
extends Node2D

## Visualizer that draws 4 animated, faded white preview paths streaming from
## the 4 corners of a spawner towards the exit, visible exclusively in between waves.

const CORNER_OFFSETS: Array[Vector2] = [
	Vector2(-26.0, -26.0),
	Vector2(26.0, -26.0),
	Vector2(26.0, 26.0),
	Vector2(-26.0, 26.0),
]

const PULSE_SPACING: float = 128.0   ## Distance between pulses in pixels
const PULSE_LENGTH: float = 16.0    ## Length of each pulse segment in pixels
const MOVE_SPEED: float = 75.0      ## Movement speed in pixels per second towards exit
const BASE_ALPHA: float = 0.15      ## Ambient continuous route alpha
const PULSE_ALPHA: float = 0.1     ## Moving pulse body alpha
const HEAD_ALPHA: float = 0.1      ## Leading pulse head dot alpha
const FADE_DISTANCE: float = 28.0   ## Edge fade-in/out distance at ends of path

class PathTrailData:
	var points: PackedVector2Array = []
	var segment_lengths: Array[float] = []
	var cumulative_lengths: Array[float] = []
	var total_length: float = 0.0

	func is_valid() -> bool:
		return points.size() >= 2 and total_length > 4.0

var spawner: Spawner = null
var _paths: Array[PathTrailData] = []
var _anim_offset: float = 0.0
var _fade_alpha: float = 0.0
var _target_fade_alpha: float = 0.0
var _fade_speed: float = 3.5
var _wave_is_active: bool = false
var _stage_is_active: bool = true
var _recalc_pending: bool = false

func _ready() -> void:
	top_level = true
	position = Vector2.ZERO
	z_index = 0
	
	if get_parent() is Spawner:
		spawner = get_parent() as Spawner
		spawner.state_changed.connect(_on_spawner_state_changed)
	
	SignalBus.wave_started.connect(_on_wave_started)
	SignalBus.wave_completed.connect(_on_wave_completed)
	SignalBus.stage_loaded.connect(_on_stage_loaded)
	SignalBus.stage_completed.connect(_on_stage_ended)
	SignalBus.stage_failed.connect(_on_stage_ended)
	SignalBus.navmesh_updated.connect(_on_navmesh_updated)
	SignalBus.spawners_updated.connect(_on_spawners_updated)
	SignalBus.exits_updated.connect(_on_exits_updated)
	
	if not NavigationServer2D.map_changed.is_connected(_on_navigation_map_changed):
		NavigationServer2D.map_changed.connect(_on_navigation_map_changed)
	
	_update_stage_wave_state()
	_update_target_visibility()
	_schedule_recalculate()

func _exit_tree() -> void:
	if NavigationServer2D.map_changed.is_connected(_on_navigation_map_changed):
		NavigationServer2D.map_changed.disconnect(_on_navigation_map_changed)

func _process(delta: float) -> void:
	_update_target_visibility()
	
	# Smoothly fade alpha in or out
	if not is_equal_approx(_fade_alpha, _target_fade_alpha):
		_fade_alpha = move_toward(_fade_alpha, _target_fade_alpha, delta * _fade_speed)
	
	if _fade_alpha > 0.001:
		_anim_offset = fmod(_anim_offset + delta * MOVE_SPEED, PULSE_SPACING * 100.0)
		queue_redraw()
	else:
		# Idle when completely hidden
		pass

func _draw() -> void:
	if _fade_alpha <= 0.001 or _paths.is_empty():
		return

	for path_data in _paths:
		if not path_data.is_valid():
			continue

		var total_len: float = path_data.total_length

		# 1. Subtle ambient continuous guide line
		draw_polyline(
			path_data.points,
			Color(1.0, 1.0, 1.0, BASE_ALPHA * _fade_alpha),
			1.5,
			true
		)

		# 2. Corner anchor dot at start of path
		var start_pt: Vector2 = path_data.points[0]
		draw_circle(start_pt, 2.8, Color(1.0, 1.0, 1.0, 0.35 * _fade_alpha))
		draw_circle(start_pt, 1.4, Color(1.0, 1.0, 1.0, 0.70 * _fade_alpha))

		# 3. Flowing animated pulses along path towards exit
		var num_pulses: int = int(ceil(total_len / PULSE_SPACING)) + 1
		for i in range(num_pulses):
			var pulse_start: float = fmod(_anim_offset + float(i) * PULSE_SPACING, total_len + PULSE_LENGTH) - PULSE_LENGTH
			var pulse_end: float = pulse_start + PULSE_LENGTH

			if pulse_end <= 0.0 or pulse_start >= total_len:
				continue

			var clamped_start: float = maxf(0.0, pulse_start)
			var clamped_end: float = minf(total_len, pulse_end)

			if clamped_start >= clamped_end or (clamped_end - clamped_start) < 0.5:
				continue

			# Smooth edge fading near start and end of path
			var mid_dist: float = (clamped_start + clamped_end) * 0.5
			var fade: float = 1.0
			if mid_dist < FADE_DISTANCE:
				fade = mid_dist / FADE_DISTANCE
			elif mid_dist > total_len - FADE_DISTANCE:
				fade = (total_len - mid_dist) / FADE_DISTANCE
			fade = clampf(fade, 0.0, 1.0) * _fade_alpha

			if fade <= 0.001:
				continue

			var sub_poly: PackedVector2Array = _sample_sub_polyline(path_data, clamped_start, clamped_end)
			if sub_poly.size() >= 2:
				# Outer soft glow line
				draw_polyline(sub_poly, Color(1.0, 1.0, 1.0, PULSE_ALPHA * fade), 2.2, true)
				# Inner crisp core line
				draw_polyline(sub_poly, Color(1.0, 1.0, 1.0, (PULSE_ALPHA + 0.25) * fade), 1.0, true)

			# Leading head pip at head of pulse
			if pulse_end > 0.0 and pulse_end <= total_len:
				var head_pos: Vector2 = _sample_point(path_data, pulse_end)
				draw_circle(head_pos, 2.0, Color(1.0, 1.0, 1.0, HEAD_ALPHA * fade))
				draw_circle(head_pos, 1.0, Color(1.0, 1.0, 1.0, 0.95 * fade))

func is_active_for_preview() -> bool:
	if not spawner or not is_instance_valid(spawner):
		return false
	return spawner.is_active or spawner.indicator_state == Spawner.IndicatorState.WILL_ACTIVATE

func is_between_waves() -> bool:
	if not _stage_is_active or _wave_is_active:
		return false
	var stage = GameManager.current_stage
	if stage and is_instance_valid(stage):
		if not stage.is_stage_active or stage.wave_is_active:
			return false
	return true

func should_show_preview() -> bool:
	return is_between_waves() and is_active_for_preview()

func _update_target_visibility() -> void:
	_target_fade_alpha = 1.0 if should_show_preview() else 0.0

func _update_stage_wave_state() -> void:
	var stage = GameManager.current_stage
	if stage and is_instance_valid(stage):
		_stage_is_active = stage.is_stage_active
		_wave_is_active = stage.wave_is_active

func _schedule_recalculate() -> void:
	if _recalc_pending or not is_inside_tree():
		return
	_recalc_pending = true
	call_deferred("_deferred_recalculate")

func _deferred_recalculate() -> void:
	_recalc_pending = false
	if not is_inside_tree():
		return
	_recalculate_paths()

func _get_target_exits() -> Array[Node2D]:
	if not spawner or not is_inside_tree():
		return []

	var active = spawner.get_active_exits()
	if not active.is_empty():
		return active

	# Fallback if no exits are currently marked active
	var fallback: Array[Node2D] = []
	if not spawner.exits.is_empty():
		for exit in spawner.exits:
			if is_instance_valid(exit):
				fallback.append(exit)
	else:
		for node in get_tree().get_nodes_in_group("exits"):
			if node is Node2D and is_instance_valid(node):
				fallback.append(node)

	return fallback

func _recalculate_paths() -> void:
	if not is_inside_tree() or not spawner or not is_instance_valid(spawner):
		_paths.clear()
		return

	var target_exits = _get_target_exits()
	if target_exits.is_empty():
		_paths.clear()
		return

	var world_2d = get_world_2d()
	if not world_2d:
		return

	var map: RID = world_2d.navigation_map
	if not map.is_valid() or NavigationServer2D.map_get_iteration_id(map) == 0:
		return

	var new_paths: Array[PathTrailData] = []

	for offset in CORNER_OFFSETS:
		var corner_global: Vector2 = spawner.global_position + offset
		var best_path: PackedVector2Array = []
		var min_length: float = INF

		for exit in target_exits:
			if not is_instance_valid(exit):
				continue
			var path = NavigationServer2D.map_get_path(map, corner_global, exit.global_position, true, 1)
			if path.size() >= 2:
				var length: float = _calc_polyline_length(path)
				if length < min_length:
					min_length = length
					best_path = path

		# If query didn't find path directly, project corner onto nearest navmesh point
		if best_path.size() < 2:
			var closest = NavigationServer2D.map_get_closest_point(map, corner_global)
			for exit in target_exits:
				if not is_instance_valid(exit):
					continue
				var path = NavigationServer2D.map_get_path(map, closest, exit.global_position, true, 1)
				if path.size() >= 2:
					var length: float = _calc_polyline_length(path)
					if length < min_length:
						min_length = length
						best_path = path

		if best_path.size() >= 2:
			new_paths.append(_build_path_data(best_path))

	_paths = new_paths
	queue_redraw()

func _build_path_data(global_path: PackedVector2Array) -> PathTrailData:
	var data = PathTrailData.new()
	if global_path.size() < 2:
		return data

	# Eliminate duplicate or near-identical adjacent vertices
	var clean_pts: PackedVector2Array = []
	for pt in global_path:
		if clean_pts.is_empty() or clean_pts[-1].distance_to(pt) > 0.5:
			clean_pts.append(pt)

	if clean_pts.size() < 2:
		return data

	data.points = clean_pts
	data.cumulative_lengths.append(0.0)
	var accum: float = 0.0

	for i in range(clean_pts.size() - 1):
		var seg_len: float = clean_pts[i].distance_to(clean_pts[i + 1])
		data.segment_lengths.append(seg_len)
		accum += seg_len
		data.cumulative_lengths.append(accum)

	data.total_length = accum
	return data

func _calc_polyline_length(poly: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(poly.size() - 1):
		total += poly[i].distance_to(poly[i + 1])
	return total

func _sample_point(data: PathTrailData, dist: float) -> Vector2:
	if data.points.is_empty():
		return Vector2.ZERO
	if dist <= 0.0:
		return data.points[0]
	if dist >= data.total_length:
		return data.points[-1]

	for i in range(data.segment_lengths.size()):
		var cum_start: float = data.cumulative_lengths[i]
		var cum_end: float = data.cumulative_lengths[i + 1]
		if dist <= cum_end:
			var seg_len: float = data.segment_lengths[i]
			if seg_len <= 0.0001:
				return data.points[i]
			var t: float = (dist - cum_start) / seg_len
			return data.points[i].lerp(data.points[i + 1], t)

	return data.points[-1]

func _sample_sub_polyline(data: PathTrailData, s_start: float, s_end: float) -> PackedVector2Array:
	if s_start >= s_end or not data.is_valid():
		return []

	s_start = clampf(s_start, 0.0, data.total_length)
	s_end = clampf(s_end, 0.0, data.total_length)
	if s_end - s_start < 0.5:
		return []

	var sub_pts: PackedVector2Array = []
	var start_pt: Vector2 = _sample_point(data, s_start)
	sub_pts.append(start_pt)

	for i in range(1, data.points.size() - 1):
		var cum_dist: float = data.cumulative_lengths[i]
		if cum_dist > s_start + 0.1 and cum_dist < s_end - 0.1:
			var mid_pt: Vector2 = data.points[i]
			if sub_pts[-1].distance_to(mid_pt) > 0.5:
				sub_pts.append(mid_pt)

	var end_pt: Vector2 = _sample_point(data, s_end)
	if sub_pts[-1].distance_to(end_pt) > 0.5:
		sub_pts.append(end_pt)

	if sub_pts.size() < 2:
		return []

	return sub_pts

# Signal Handlers
func _on_navigation_map_changed(changed_map: RID) -> void:
	if not is_inside_tree():
		return
	var world_2d = get_world_2d()
	if world_2d and changed_map == world_2d.navigation_map:
		_schedule_recalculate()

func _on_wave_started() -> void:
	_wave_is_active = true
	_update_target_visibility()

func _on_wave_completed() -> void:
	_wave_is_active = false
	_update_stage_wave_state()
	_update_target_visibility()
	_schedule_recalculate()

func _on_stage_loaded() -> void:
	_stage_is_active = true
	_wave_is_active = false
	_update_stage_wave_state()
	_update_target_visibility()
	_schedule_recalculate()

func _on_stage_ended() -> void:
	_stage_is_active = false
	_update_target_visibility()

func _on_navmesh_updated() -> void:
	_schedule_recalculate()

func _on_spawners_updated() -> void:
	_update_target_visibility()
	_schedule_recalculate()

func _on_exits_updated() -> void:
	_schedule_recalculate()

func _on_spawner_state_changed(_is_active: bool) -> void:
	_update_target_visibility()
	_schedule_recalculate()

func update_preview() -> void:
	_update_target_visibility()
	_schedule_recalculate()
