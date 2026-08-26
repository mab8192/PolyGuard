class_name TowerPlacementManager extends Node

const GRID_SIZE = 32
const TOWER_TOUCH_DIST_THRESH: float = 96.0

var stage: Stage
var wave_manager: WaveManager

var preview_tower: Tower = null
var preview_pos: Vector2 = Vector2.ZERO
var total_drag_distance_sq: float = 0.0
var is_dragging: bool = false
var last_input_pos: Vector2 = Vector2.ZERO
var drag_speed_modifier: float = 1.0
var current_rotation_degrees: float = 0.0

var _is_placement_active: bool = false

func setup(p_stage: Stage, p_wave_manager: WaveManager) -> void:
	stage = p_stage
	wave_manager = p_wave_manager
	SignalBus.wave_started.connect(exit_placement_mode)

func _process(_delta: float) -> void:
	if is_instance_valid(preview_tower):
		var valid: bool = can_place_preview()
		preview_tower.modulate = Color(0.5, 1.0, 0.5, 0.7) if valid else Color(1.0, 0.4, 0.4, 0.7)

func enter_placement_mode(tower_input: TowerData) -> void:
	exit_placement_mode()
	current_rotation_degrees = 0.0
	
	# Center on screen in world coordinates (snapped to the placement grid)
	var center_pos = Vector2.ZERO
	if GameManager.camera:
		center_pos = GameManager.camera.global_position
	else:
		center_pos = get_viewport().get_visible_rect().size / 2.0
	
	_create_preview_tower(tower_input, center_pos)
	
	_is_placement_active = true
	SignalBus.placement_mode_changed.emit(true)

func _create_preview_tower(tower_data: TowerData, pos: Vector2) -> void:
	if preview_tower:
		preview_tower.queue_free()
		preview_tower = null

	is_dragging = false
	total_drag_distance_sq = 0.0
	
	preview_tower = tower_data.create()
	if not preview_tower:
		push_error("Must be a tower scene!")
		return

	if stage and stage.towers:
		stage.towers.add_child(preview_tower)
	
	preview_tower.is_preview = true
	preview_tower.rotation_degrees = current_rotation_degrees
	
	var snapped_pos = _snap_to_grid(pos)
	preview_tower.global_position = snapped_pos
	preview_pos = snapped_pos

func rotate_preview(clockwise: bool = true) -> void:
	if not is_in_placement_mode() or not preview_tower.data:
		return
	if not preview_tower.data.can_rotate or preview_tower.data.rotation_step_degrees <= 0.0:
		return
	
	var step: float = preview_tower.data.rotation_step_degrees
	var dir: float = 1.0 if clockwise else -1.0
	current_rotation_degrees = fposmod(current_rotation_degrees + (step * dir), 360.0)
	preview_tower.rotation_degrees = current_rotation_degrees

func can_preview_rotate() -> bool:
	return is_in_placement_mode() and preview_tower.data != null and preview_tower.data.can_rotate and preview_tower.data.rotation_step_degrees > 0.0

func exit_placement_mode() -> void:
	if is_instance_valid(preview_tower):
		preview_tower.queue_free()
		preview_tower = null
	is_dragging = false
	if _is_placement_active:
		_is_placement_active = false
		SignalBus.placement_mode_changed.emit(false)

func is_in_placement_mode() -> bool:
	return _is_placement_active and is_instance_valid(preview_tower)

func get_preview_tower_position() -> Vector2:
	if is_in_placement_mode():
		return preview_tower.global_position
	return Vector2.ZERO

func can_place_preview() -> bool:
	if not is_instance_valid(preview_tower):
		return false

	# 1. Energy check
	if stage and preview_tower.data and preview_tower.data.cost > stage.energy:
		return false

	var preview_rect: Rect2 = _get_tower_global_rect(preview_tower)

	# 2. Map boundary check
	if stage:
		var map_rect: Rect2 = stage.get_map_pixel_rect()
		if map_rect.has_area() and not map_rect.grow(0.1).encloses(preview_rect):
			return false

		# 3. Tilemap terrain check (every cell covered by preview_rect must be walkable)
		if stage.tiles:
			var tiles = stage.tiles
			var min_cell: Vector2i = tiles.local_to_map(tiles.to_local(preview_rect.position + Vector2(1, 1)))
			var max_cell: Vector2i = tiles.local_to_map(tiles.to_local(preview_rect.end - Vector2(1, 1)))

			for x in range(min_cell.x, max_cell.x + 1):
				for y in range(min_cell.y, max_cell.y + 1):
					var cell_pos := Vector2i(x, y)
					var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
					if tile_data and tile_data.get_collision_polygons_count(0) > 0:
						return false

		# 4. Check for overlap with already placed towers (use 0.1px inset to avoid edge-touching float precision false positives)
		if stage.towers:
			for child in stage.towers.get_children():
				if child is Tower and child != preview_tower and not child.is_preview and not child.is_queued_for_deletion():
					var child_rect: Rect2 = _get_tower_global_rect(child)
					if preview_rect.grow(-0.1).intersects(child_rect.grow(-0.1)):
						if not _can_overlap_tower(preview_tower, child):
							return false

	# 5. Check for overlap with active enemies
	if preview_tower.collision_layer > 0:
		var enemy_nodes: Array = []
		if GameManager.stage_root:
			enemy_nodes = GameManager.stage_root.enemies.get_children()
		else:
			enemy_nodes = get_tree().get_nodes_in_group("enemies")

		for enemy in enemy_nodes:
			if enemy is CharacterBody2D and is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
				if preview_rect.grow(16.0).has_point(enemy.global_position):
					return false

	# 6. Check for overlap with spawners and exits
	var spawner_and_exit_nodes: Array = []
	spawner_and_exit_nodes.append_array(get_tree().get_nodes_in_group("spawners"))
	spawner_and_exit_nodes.append_array(get_tree().get_nodes_in_group("exits"))

	for obj in spawner_and_exit_nodes:
		if obj is Node2D and is_instance_valid(obj) and not obj.is_queued_for_deletion():
			var obj_rect: Rect2 = _get_tower_global_rect(obj)
			if preview_rect.grow(-0.1).intersects(obj_rect.grow(-0.1)):
				return false

	# 7. Check solid structure backing requirement for wall traps
	if not _has_solid_structure_behind(preview_tower):
		return false

	return true

func place_preview() -> void:
	if not preview_tower:
		return

	if not can_place_preview():
		return

	var tower_data: TowerData = preview_tower.data
	var last_pos: Vector2 = preview_tower.global_position

	# Deduct energy and place tower
	if stage:
		stage.deduct_energy(preview_tower.data.cost)
	
	preview_tower.is_preview = false
	preview_tower.modulate = Color.WHITE
	
	SignalBus.tower_placed.emit()
	
	preview_tower = null
	is_dragging = false
	
	if tower_data and stage and stage.energy >= tower_data.cost:
		var adjacent_offsets: Array[Vector2] = [
			Vector2(GRID_SIZE * 2, 0),
			Vector2(0, GRID_SIZE * 2),
			Vector2(-GRID_SIZE * 2, 0),
			Vector2(0, -GRID_SIZE * 2)
		]
		var spawned: bool = false
		for offset in adjacent_offsets:
			var test_pos = last_pos + offset
			_create_preview_tower(tower_data, test_pos)
			if can_place_preview():
				spawned = true
				break
		if not spawned:
			exit_placement_mode()
	else:
		exit_placement_mode()

func handle_unhandled_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		if is_in_placement_mode():
			exit_placement_mode()
			return true

	if preview_tower == null:
		return false

	# Keyboard rotation shortcuts
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_R:
			if event.shift_pressed:
				rotate_preview(false)
			else:
				rotate_preview(true)
			return true
		elif event.keycode == KEY_Q:
			rotate_preview(false)
			return true
		elif event.keycode == KEY_E:
			rotate_preview(true)
			return true

	var pos = stage.get_global_mouse_position() if stage else Vector2.ZERO
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				_handle_press(pos)
				return true
			else:
				if is_dragging:
					_handle_release(pos)
					return true
		elif event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				rotate_preview(true)
				return true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				rotate_preview(false)
				return true
	elif event is InputEventMouseMotion:
		if is_dragging:
			_handle_drag(pos - last_input_pos)
			last_input_pos = pos
			return true
			
	return false

func _handle_press(pos: Vector2) -> void:
	is_dragging = true
	last_input_pos = pos
	total_drag_distance_sq = 0.0
	
	if preview_tower:
		var dist = pos.distance_to(preview_tower.global_position)
		drag_speed_modifier = 1.0 if dist < TOWER_TOUCH_DIST_THRESH else 0.5
	
func _handle_release(_pos: Vector2) -> void:
	if not is_dragging:
		return
	is_dragging = false
	
	if preview_tower:
		var on_tower = _pos.distance_to(preview_tower.global_position) < TOWER_TOUCH_DIST_THRESH
		if total_drag_distance_sq < 25 and on_tower and can_place_preview():
			place_preview()
	
func _handle_drag(delta: Vector2) -> void:
	if not is_dragging or not preview_tower:
		return
	
	delta *= drag_speed_modifier
	
	preview_pos += delta
	total_drag_distance_sq += delta.length_squared()
	
	preview_tower.global_position = _snap_to_grid(preview_pos)

func _snap_to_grid(glob_pos: Vector2) -> Vector2:
	return glob_pos.snapped(Vector2(GRID_SIZE, GRID_SIZE))

func _get_tower_global_rect(node: Node2D) -> Rect2:
	if not is_instance_valid(node):
		return Rect2(-Vector2(16, 16), Vector2(32, 32))

	for child in node.get_children():
		if child is CollisionShape2D and child.shape:
			var shape = child.shape
			if shape is RectangleShape2D:
				var half_size: Vector2 = shape.size / 2.0
				var corners = [
					Vector2(-half_size.x, -half_size.y),
					Vector2(half_size.x, -half_size.y),
					Vector2(half_size.x, half_size.y),
					Vector2(-half_size.x, half_size.y)
				]
				var g_min: Vector2 = child.to_global(corners[0])
				var g_max: Vector2 = g_min
				for i in range(1, 4):
					var g_pt: Vector2 = child.to_global(corners[i])
					g_min.x = minf(g_min.x, g_pt.x)
					g_min.y = minf(g_min.y, g_pt.y)
					g_max.x = maxf(g_max.x, g_pt.x)
					g_max.y = maxf(g_max.y, g_pt.y)
				g_min.x = snappedf(g_min.x, 0.001)
				g_min.y = snappedf(g_min.y, 0.001)
				g_max.x = snappedf(g_max.x, 0.001)
				g_max.y = snappedf(g_max.y, 0.001)
				return Rect2(g_min, g_max - g_min)
			elif shape is CircleShape2D:
				var r = shape.radius
				var center = child.to_global(Vector2.ZERO)
				var g_min = Vector2(snappedf(center.x - r, 0.001), snappedf(center.y - r, 0.001))
				var g_size = Vector2(snappedf(r * 2.0, 0.001), snappedf(r * 2.0, 0.001))
				return Rect2(g_min, g_size)
			elif shape is CapsuleShape2D:
				var r = shape.radius
				var h = shape.height
				var half_h = maxf(0.0, (h / 2.0) - r)
				var top_center = child.to_global(Vector2(0, -half_h))
				var bot_center = child.to_global(Vector2(0, half_h))
				var g_min = Vector2(minf(top_center.x, bot_center.x) - r, minf(top_center.y, bot_center.y) - r)
				var g_max = Vector2(maxf(top_center.x, bot_center.x) + r, maxf(top_center.y, bot_center.y) + r)
				g_min.x = snappedf(g_min.x, 0.001)
				g_min.y = snappedf(g_min.y, 0.001)
				g_max.x = snappedf(g_max.x, 0.001)
				g_max.y = snappedf(g_max.y, 0.001)
				return Rect2(g_min, g_max - g_min)
		elif child is CollisionPolygon2D and child.polygon.size() > 0:
			var g_min = child.to_global(child.polygon[0])
			var g_max = g_min
			for pt in child.polygon:
				var g_pt = child.to_global(pt)
				g_min.x = minf(g_min.x, g_pt.x)
				g_min.y = minf(g_min.y, g_pt.y)
				g_max.x = maxf(g_max.x, g_pt.x)
				g_max.y = maxf(g_max.y, g_pt.y)
			g_min.x = snappedf(g_min.x, 0.001)
			g_min.y = snappedf(g_min.y, 0.001)
			g_max.x = snappedf(g_max.x, 0.001)
			g_max.y = snappedf(g_max.y, 0.001)
			return Rect2(g_min, g_max - g_min)

	var color_rect = node.find_child("ColorRect", false, false) as ColorRect
	if color_rect:
		var rect = color_rect.get_rect()
		var corners = [
			rect.position,
			rect.position + Vector2(rect.size.x, 0),
			rect.position + rect.size,
			rect.position + Vector2(0, rect.size.y)
		]
		var g_min = color_rect.to_global(corners[0])
		var g_max = g_min
		for i in range(1, 4):
			var g_pt = color_rect.to_global(corners[i])
			g_min.x = minf(g_min.x, g_pt.x)
			g_min.y = minf(g_min.y, g_pt.y)
			g_max.x = maxf(g_max.x, g_pt.x)
			g_max.y = maxf(g_max.y, g_pt.y)
		g_min.x = snappedf(g_min.x, 0.001)
		g_min.y = snappedf(g_min.y, 0.001)
		g_max.x = snappedf(g_max.x, 0.001)
		g_max.y = snappedf(g_max.y, 0.001)
		return Rect2(g_min, g_max - g_min)

	var default_half = Vector2(GRID_SIZE, GRID_SIZE)
	return Rect2(node.global_position - default_half, default_half * 2.0)

func _can_overlap_tower(preview: Tower, existing: Tower) -> bool:
	var preview_is_wall: bool = preview.data != null and preview.data.requires_wall_behind
	var existing_is_wall: bool = existing.data != null and existing.data.requires_wall_behind
	var preview_is_ground: bool = (preview.collision_layer == 0 or (preview.data and preview.data.collision_layer == 0)) and not preview_is_wall
	var existing_is_ground: bool = existing.collision_layer == 0 and not existing_is_wall

	# Wall traps and ground traps can intersect each other
	if (preview_is_wall and existing_is_ground) or (preview_is_ground and existing_is_wall):
		return true

	return false

func _has_solid_structure_behind(tower: Tower) -> bool:
	if not tower or not tower.data or not tower.data.requires_wall_behind:
		return true

	var sample_offsets: Array[Vector2] = [
		Vector2(-40, -16),
		Vector2(-40, 0),
		Vector2(-40, 16)
	]

	for offset in sample_offsets:
		var sample_point: Vector2 = tower.to_global(offset)
		if not _is_solid_structure_at(sample_point, tower):
			return false

	return true

func _is_solid_structure_at(global_pos: Vector2, ignore_tower: Tower = null) -> bool:
	if not stage:
		return false

	# 1. Check tilemap solid wall
	if stage.tiles:
		var tiles: TileMapLayer = stage.tiles
		var cell_pos: Vector2i = tiles.local_to_map(tiles.to_local(global_pos))
		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			return true

	# 2. Check placed solid towers/structures (collision_layer > 0)
	if stage.towers:
		for child in stage.towers.get_children():
			if child is Tower and child != preview_tower and child != ignore_tower and not child.is_preview and not child.is_queued_for_deletion():
				if child.collision_layer > 0:
					var child_rect: Rect2 = _get_tower_global_rect(child)
					if child_rect.grow(0.5).has_point(global_pos):
						return true

	return false
