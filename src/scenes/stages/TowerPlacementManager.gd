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

var _is_placement_active: bool = false

func setup(p_stage: Stage, p_wave_manager: WaveManager) -> void:
	stage = p_stage
	wave_manager = p_wave_manager
	SignalBus.wave_started.connect(exit_placement_mode)

func _process(_delta: float) -> void:
	if preview_tower and is_instance_valid(preview_tower):
		var valid: bool = can_place_preview()
		preview_tower.modulate = Color(0.5, 1.0, 0.5, 0.7) if valid else Color(1.0, 0.4, 0.4, 0.7)

func enter_placement_mode(tower_input: TowerData) -> void:
	exit_placement_mode()
	
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
	
	var snapped_pos = _snap_to_grid(pos)
	preview_tower.global_position = snapped_pos
	preview_pos = snapped_pos

func exit_placement_mode() -> void:
	if preview_tower and is_instance_valid(preview_tower):
		preview_tower.queue_free()
		preview_tower = null
	is_dragging = false
	if _is_placement_active:
		_is_placement_active = false
		SignalBus.placement_mode_changed.emit(false)

func is_in_placement_mode() -> bool:
	return _is_placement_active and preview_tower != null and is_instance_valid(preview_tower)

func get_preview_tower_position() -> Vector2:
	if is_in_placement_mode():
		return preview_tower.global_position
	return Vector2.ZERO

func can_place_preview() -> bool:
	if not preview_tower or not is_instance_valid(preview_tower):
		return false

	if stage and preview_tower.data and preview_tower.data.cost > stage.gold:
		return false

	var preview_rect: Rect2 = _get_tower_global_rect(preview_tower)

	# 1. Map boundary check
	if stage:
		var map_rect: Rect2 = stage.get_map_pixel_rect()
		if map_rect.has_area() and not map_rect.encloses(preview_rect):
			return false

		# 2. Tilemap terrain check (every cell covered by preview_rect must be walkable)
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

		# 3. Check for overlap with already placed towers
		if stage.towers:
			for child in stage.towers.get_children():
				if child is Tower and child != preview_tower and not child.is_preview:
					var child_rect: Rect2 = _get_tower_global_rect(child)
					if preview_rect.intersects(child_rect):
						return false

	# 4. Check for overlap with active enemies
	if preview_tower.is_solid:
		var enemy_nodes: Array = []
		if GameManager and GameManager.stage_root and GameManager.stage_root.enemies:
			enemy_nodes = GameManager.stage_root.enemies.get_children()
		else:
			enemy_nodes = get_tree().get_nodes_in_group("enemies")

		for enemy in enemy_nodes:
			if enemy is CharacterBody2D and is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
				if preview_rect.grow(16.0).has_point(enemy.global_position):
					return false

	# 5. Check for overlap with spawners and exits
	var spawner_and_exit_nodes: Array = []
	spawner_and_exit_nodes.append_array(get_tree().get_nodes_in_group("spawners"))
	spawner_and_exit_nodes.append_array(get_tree().get_nodes_in_group("exits"))

	for obj in spawner_and_exit_nodes:
		if obj is Node2D and is_instance_valid(obj) and not obj.is_queued_for_deletion():
			var obj_rect: Rect2 = _get_tower_global_rect(obj)
			if preview_rect.intersects(obj_rect):
				return false

	return true

func place_preview() -> void:
	if not preview_tower:
		return

	if not can_place_preview():
		return

	var tower_data: TowerData = preview_tower.data
	var last_pos: Vector2 = preview_tower.global_position

	# Deduct gold and place tower
	if stage:
		stage.deduct_gold(preview_tower.data.cost)
	
	preview_tower.is_preview = false
	preview_tower.modulate = Color.WHITE
	
	SignalBus.tower_placed.emit()
	
	preview_tower = null
	is_dragging = false
	
	if tower_data and stage and stage.gold >= tower_data.cost:
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

	var pos = stage.get_global_mouse_position() if stage else Vector2.ZERO
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_handle_press(pos)
			return true
		else:
			if is_dragging:
				_handle_release(pos)
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
		if total_drag_distance_sq < 100 and on_tower and can_place_preview():
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

func _get_tower_local_rect(node: Node2D) -> Rect2:
	if not is_instance_valid(node):
		return Rect2(-Vector2(16, 16), Vector2(32, 32))

	for child in node.get_children():
		if child is CollisionShape2D and child.shape:
			var shape = child.shape
			if shape is RectangleShape2D:
				var size = shape.size
				return Rect2(child.position - size / 2.0, size)
			elif shape is CircleShape2D:
				var r = shape.radius
				return Rect2(child.position - Vector2(r, r), Vector2(r * 2, r * 2))
			elif shape is CapsuleShape2D:
				var r = shape.radius
				var h = shape.height
				var size = Vector2(r * 2, h)
				return Rect2(child.position - size / 2.0, size)
		elif child is CollisionPolygon2D and child.polygon.size() > 0:
			var min_pt = child.polygon[0]
			var max_pt = child.polygon[0]
			for pt in child.polygon:
				min_pt.x = minf(min_pt.x, pt.x)
				min_pt.y = minf(min_pt.y, pt.y)
				max_pt.x = maxf(max_pt.x, pt.x)
				max_pt.y = maxf(max_pt.y, pt.y)
			return Rect2(child.position + min_pt, max_pt - min_pt)

	var color_rect = node.find_child("ColorRect", false, false) as ColorRect
	if color_rect:
		return color_rect.get_rect()

	return Rect2(-Vector2(GRID_SIZE, GRID_SIZE), Vector2(GRID_SIZE * 2, GRID_SIZE * 2))

func _get_tower_global_rect(node: Node2D) -> Rect2:
	var local_rect: Rect2 = _get_tower_local_rect(node)
	return Rect2(node.global_position + local_rect.position, local_rect.size)
