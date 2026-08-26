class_name Stage extends Node2D

var data: StageData

@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles
@onready var towers: Node2D = $NavigationRegion2D/Towers

var wave_manager: WaveManager
var placement_manager: TowerPlacementManager
var effect_manager: EffectManager
var flow_field_visualizer: FlowFieldVisualizer

# Stage economy and life tracking state
var lives: int
var energy: int
var gold: int:
	get: return energy
	set(v): energy = v
var score: int = 0
var selected_tower: Tower = null

# Accessors delegated to WaveManager for external callers
var wave: int:
	get: return wave_manager.wave if wave_manager else 0
	set(v): if wave_manager: wave_manager.wave = v

var current_wave: WaveData:
	get: return wave_manager.current_wave if wave_manager else null

var stage_time: float:
	get: return wave_manager.stage_time if wave_manager else 0.0

var is_stage_active: bool:
	get: return wave_manager.is_stage_active if wave_manager else false
	set(v): if wave_manager: wave_manager.is_stage_active = v

var wave_is_active: bool:
	get: return wave_manager.wave_is_active if wave_manager else false

var spawners: Array[Spawner]:
	get: return wave_manager.spawners if wave_manager else []

func _ready() -> void:
	if data:
		lives = data.starting_lives
		energy = data.starting_energy
	
	SignalBus.lives_changed.emit(lives)
	SignalBus.energy_changed.emit(energy)
	SignalBus.score_changed.emit(score)
	
	wave_manager = WaveManager.new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)
	
	placement_manager = TowerPlacementManager.new()
	placement_manager.name = "TowerPlacementManager"
	add_child(placement_manager)

	flow_field_visualizer = FlowFieldVisualizer.new()
	flow_field_visualizer.name = "FlowFieldVisualizer"
	add_child(flow_field_visualizer)

	effect_manager = EffectManager.new()
	
	effect_manager.setup()
	wave_manager.setup(self)
	placement_manager.setup(self, wave_manager)
	
	SignalBus.tower_placed.connect(_rebuild_flow_fields)
	SignalBus.tower_destroyed.connect(_on_tower_destroyed)
	SignalBus.exits_updated.connect(_setup_flow_fields)
	
	_setup_flow_fields()

func _unhandled_input(event: InputEvent) -> void:
	if placement_manager and placement_manager.handle_unhandled_input(event):
		get_viewport().set_input_as_handled()
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		var click_pos: Vector2 = get_global_mouse_position()
		var clicked_tower: Tower = _find_tower_at(click_pos)
		if clicked_tower:
			select_tower(clicked_tower)
			get_viewport().set_input_as_handled()
			return
		elif selected_tower:
			deselect_tower()
			get_viewport().set_input_as_handled()
			return
		
	if event.is_action_pressed("ui_cancel"):
		if selected_tower:
			deselect_tower()
			get_viewport().set_input_as_handled()
			return
		var hud: Node = get_tree().current_scene.find_child("HUD", true, false)
		if hud and hud.has_method("open_pause_menu"):
			hud.open_pause_menu()
			get_viewport().set_input_as_handled()

func _find_tower_at(pos: Vector2) -> Tower:
	if not towers:
		return null
	
	var candidates: Array[Tower] = []
	for child: Node in towers.get_children():
		if child is Tower and is_instance_valid(child) and not (child as Tower).is_preview and not child.is_queued_for_deletion():
			var rect: Rect2 = _get_tower_global_rect(child as Node2D).grow(8.0)
			if rect.has_point(pos):
				candidates.append(child as Tower)
	
	if candidates.is_empty():
		return null
	
	# Sort candidates: higher z_index first (top-most visual layer), then closer rect center to click position
	candidates.sort_custom(func(a: Tower, b: Tower) -> bool:
		if a.z_index != b.z_index:
			return a.z_index > b.z_index
		var rect_a = _get_tower_global_rect(a)
		var rect_b = _get_tower_global_rect(b)
		return rect_a.get_center().distance_squared_to(pos) < rect_b.get_center().distance_squared_to(pos)
	)

	# If the currently selected tower is in the candidates list and there are multiple, cycle to the next candidate
	if is_instance_valid(selected_tower):
		var current_idx: int = candidates.find(selected_tower)
		if current_idx != -1 and candidates.size() > 1:
			return candidates[(current_idx + 1) % candidates.size()]
	
	return candidates[0]

func _get_tower_global_rect(node: Node2D) -> Rect2:
	if placement_manager:
		return placement_manager._get_tower_global_rect(node)
	return Rect2(node.global_position - Vector2(32, 32), Vector2(64, 64))

### PUBLIC API & ECONOMY HELPERS

func select_tower(tower: Tower) -> void:
	if selected_tower == tower:
		return
	
	if is_instance_valid(selected_tower):
		selected_tower.is_selected = false
	
	selected_tower = tower
	if is_instance_valid(selected_tower):
		selected_tower.is_selected = true
		SignalBus.tower_selected.emit(selected_tower)
	else:
		SignalBus.tower_deselected.emit()

func deselect_tower() -> void:
	if is_instance_valid(selected_tower):
		selected_tower.is_selected = false
	selected_tower = null
	SignalBus.tower_deselected.emit()

func get_selected_tower() -> Tower:
	if is_instance_valid(selected_tower):
		return selected_tower
	return null

func sell_selected_tower() -> void:
	if not is_instance_valid(selected_tower):
		return
	
	var tower_to_sell: Tower = selected_tower
	var sell_value: int = tower_to_sell.get_sell_value()
	
	deselect_tower()
	add_energy(sell_value)
	SignalBus.tower_sold.emit(tower_to_sell, sell_value)
	tower_to_sell._on_died()

func repair_selected_tower() -> bool:
	if not is_instance_valid(selected_tower):
		return false
	var cost: int = selected_tower.get_repair_cost()
	if cost <= 0 or energy < cost:
		return false
	deduct_energy(cost)
	var success: bool = selected_tower.repair()
	return success

func deduct_energy(amount: int) -> void:
	energy -= amount
	SignalBus.energy_changed.emit(energy)

func add_energy(amount: int) -> void:
	energy += amount
	SignalBus.energy_changed.emit(energy)

func deduct_gold(amount: int) -> void:
	deduct_energy(amount)

func add_gold(amount: int) -> void:
	add_energy(amount)

func add_score(amount: int) -> void:
	score += amount
	SignalBus.score_changed.emit(score)

func take_lives(amount: int) -> void:
	lives -= amount
	if lives <= 0:
		lives = 0
		is_stage_active = false
		SignalBus.lives_changed.emit(lives)
		SignalBus.stage_failed.emit()
	else:
		SignalBus.lives_changed.emit(lives)

func get_towers() -> Array[Tower]:
	var list: Array[Tower] = []
	if towers:
		for child in towers.get_children():
			if is_instance_valid(child) and child is Tower and not child.is_queued_for_deletion() and not (child as Tower).is_preview:
				list.append(child as Tower)
	return list


func get_map_pixel_rect() -> Rect2:
	var used_rect: Rect2i = tiles.get_used_rect()
	if not used_rect.has_area():
		return Rect2(tiles.global_position, Vector2.ZERO)
		
	var half_tile: Vector2 = Vector2(tiles.tile_set.tile_size) / 2.0

	# 1. Get the pixel centers of the extreme outer tiles
	var top_left_center: Vector2 = tiles.map_to_local(used_rect.position)
	var bottom_right_center: Vector2 = tiles.map_to_local(used_rect.end - Vector2i(1, 1))

	# 2. Expand out to the physical edges of those tiles
	var local_min: Vector2 = top_left_center - half_tile
	var local_max: Vector2 = bottom_right_center + half_tile

	# 3. Apply the node's transform/scale to convert to global coordinates
	var global_min: Vector2 = tiles.to_global(local_min)
	var global_size: Vector2 = (local_max - local_min) * tiles.scale

	return Rect2(global_min, global_size)

func start_next_wave() -> void:
	if wave_manager:
		wave_manager.start_next_wave()

func enter_placement_mode(tower_input: TowerData) -> void:
	deselect_tower()
	if placement_manager:
		placement_manager.enter_placement_mode(tower_input)

func exit_placement_mode() -> void:
	if placement_manager:
		placement_manager.exit_placement_mode()

func is_in_placement_mode() -> bool:
	return placement_manager.is_in_placement_mode() if placement_manager else false

func get_preview_tower_position() -> Vector2:
	return placement_manager.get_preview_tower_position() if placement_manager else Vector2.ZERO

func can_place_preview() -> bool:
	return placement_manager.can_place_preview() if placement_manager else false

func can_preview_rotate() -> bool:
	return placement_manager.can_preview_rotate() if placement_manager else false

func rotate_preview(clockwise: bool = true) -> void:
	if placement_manager:
		placement_manager.rotate_preview(clockwise)

func place_preview() -> void:
	if placement_manager:
		placement_manager.place_preview()

### FLOW FIELD PATHFINDING MANAGEMENT

func _get_stage_exits() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var exit_nodes: Array[Node] = get_tree().get_nodes_in_group("exits")
	for node: Node in exit_nodes:
		if is_instance_valid(node) and node is Node2D:
			var ex: Node2D = node as Node2D
			if ex is Exit and not (ex as Exit).is_active:
				continue
			result.append(ex)
	return result

func _setup_flow_fields() -> void:
	if not tiles:
		return
		
	var map_rect: Rect2 = get_map_pixel_rect()
	if map_rect.size.x <= 0 or map_rect.size.y <= 0:
		return

	const CELL_SIZE: float = 16.0
	# Align grid origin and dimensions to exact multiples of 16px cell size for perfect tile alignment
	var min_x: float = floor((map_rect.position.x - CELL_SIZE) / CELL_SIZE) * CELL_SIZE
	var min_y: float = floor((map_rect.position.y - CELL_SIZE) / CELL_SIZE) * CELL_SIZE
	var max_x: float = ceil((map_rect.end.x + CELL_SIZE) / CELL_SIZE) * CELL_SIZE
	var max_y: float = ceil((map_rect.end.y + CELL_SIZE) / CELL_SIZE) * CELL_SIZE

	var origin := Vector2(min_x, min_y)
	var gw: int = maxi(1, int(round((max_x - min_x) / CELL_SIZE)))
	var gh: int = maxi(1, int(round((max_y - min_y) / CELL_SIZE)))

	# Unified 16px fields with tier-based obstacle clearance dilation
	var tiers := {
		"small": {"radius": 0, "added_cost": 0.0},
		"medium": {"radius": 1, "added_cost": 4.0},
		"large": {"radius": 2, "added_cost": 8.0}
	}

	var exit_nodes := _get_stage_exits()
	var exit_count: int = exit_nodes.size()

	FlowFieldManager.clear()
	FlowFieldManager.setup_astar(gw, gh, CELL_SIZE, origin)

	for tier_name: String in tiers:
		var cfg: Dictionary = tiers[tier_name]
		var radius: int = int(cfg["radius"])
		var added_cost: float = float(cfg["added_cost"])

		# Unified multi-goal fields
		var p_field: FlowField = FlowFieldManager.create_field("physical_%s" % tier_name, gw, gh, CELL_SIZE, origin)
		if p_field:
			p_field.padding_radius = radius
			p_field.padding_added_cost = added_cost

		var g_field: FlowField = FlowFieldManager.create_field("ghost_%s" % tier_name, gw, gh, CELL_SIZE, origin)
		if g_field:
			g_field.padding_radius = radius
			g_field.padding_added_cost = added_cost

		# Per-exit fields if multi-exit stage
		if exit_count > 1:
			for e_i in range(exit_count):
				var p_e_field: FlowField = FlowFieldManager.create_field("physical_%s_%d" % [tier_name, e_i], gw, gh, CELL_SIZE, origin)
				if p_e_field:
					p_e_field.padding_radius = radius
					p_e_field.padding_added_cost = added_cost

				var g_e_field: FlowField = FlowFieldManager.create_field("ghost_%s_%d" % [tier_name, e_i], gw, gh, CELL_SIZE, origin)
				if g_e_field:
					g_e_field.padding_radius = radius
					g_e_field.padding_added_cost = added_cost

	_rebuild_flow_fields()

var _is_cleaning_unsupported_traps: bool = false

func _on_tower_destroyed() -> void:
	if is_instance_valid(selected_tower) and selected_tower.is_queued_for_deletion():
		deselect_tower()
	_cleanup_unsupported_wall_traps()
	_rebuild_flow_fields()

func _cleanup_unsupported_wall_traps() -> void:
	if _is_cleaning_unsupported_traps or not placement_manager or not towers:
		return

	_is_cleaning_unsupported_traps = true
	var unsupported_traps: Array[Tower] = []
	for child in towers.get_children():
		if child is Tower and is_instance_valid(child) and not child.is_preview and not child.is_queued_for_deletion():
			if child.data and child.data.requires_wall_behind:
				if not placement_manager._has_solid_structure_behind(child):
					unsupported_traps.append(child)

	for trap in unsupported_traps:
		if is_instance_valid(trap) and not trap.is_queued_for_deletion():
			if selected_tower == trap:
				deselect_tower()
			trap._on_died()
	_is_cleaning_unsupported_traps = false

func _rebuild_flow_fields() -> void:
	var exit_nodes := _get_stage_exits()
	var exit_rects: Array[Rect2] = []
	for ex in exit_nodes:
		if is_instance_valid(ex):
			if ex.has_method("get_global_rect"):
				exit_rects.append(ex.get_global_rect())
			else:
				exit_rects.append(Rect2(ex.global_position - Vector2(16.0, 16.0), Vector2(32.0, 32.0)))

	if exit_rects.is_empty():
		return

	# Gather active tower rects partitioned by collision type
	var physical_tower_rects: Array[Rect2] = []
	var spectral_tower_rects: Array[Rect2] = []
	for tower in get_towers():
		if (tower.collision_layer & 2) != 0:
			physical_tower_rects.append(_get_tower_global_rect(tower))
		if (tower.collision_layer & 16) != 0:
			spectral_tower_rects.append(_get_tower_global_rect(tower))

	# Rebuild AStar pathfinding grid
	FlowFieldManager.reset_astar()
	if tiles and tiles.tile_set:
		var used_cells: Array[Vector2i] = tiles.get_used_cells()
		var tile_size: Vector2 = Vector2(tiles.tile_set.tile_size) * tiles.scale
		var half_tile: Vector2 = tile_size / 2.0
		for cell_pos: Vector2i in used_cells:
			var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
				var wall_rect: Rect2 = Rect2(global_center - half_tile, tile_size)
				FlowFieldManager.set_astar_rect_solid(wall_rect, true)

	for rect: Rect2 in physical_tower_rects:
		FlowFieldManager.set_astar_rect_weight(rect, 4.0)

	# Rebuild every registered field in FlowFieldManager
	for field_id: String in FlowFieldManager.fields:
		var field: FlowField = FlowFieldManager.get_field(field_id)
		if not field:
			continue

		field.reset()

		# 1. Mark impassable tilemap walls
		_stamp_tilemap_walls(field)

		# 2. Mark towers
		if field_id.begins_with("physical"):
			for rect: Rect2 in physical_tower_rects:
				field.set_obstructed(rect)
		elif field_id.begins_with("ghost"):
			for rect: Rect2 in spectral_tower_rects:
				field.set_obstructed(rect)

		# 3. Add targets as entire exit rectangles
		field.clear_targets()
		var parts := field_id.split("_")
		if parts.size() >= 3 and parts[2].is_valid_int():
			var exit_idx: int = int(parts[2])
			if exit_idx < exit_rects.size():
				field.add_target(exit_rects[exit_idx])
		else:
			for er: Rect2 in exit_rects:
				field.add_target(er)

		field.rebuild()

	FlowFieldManager.notify_fields_updated()

func _stamp_tilemap_walls(field: FlowField) -> void:
	if not tiles or not tiles.tile_set:
		return

	var used_cells: Array[Vector2i] = tiles.get_used_cells()
	var tile_size: Vector2 = Vector2(tiles.tile_set.tile_size) * tiles.scale
	var half_tile: Vector2 = tile_size / 2.0

	for cell_pos: Vector2i in used_cells:
		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
			var wall_rect: Rect2 = Rect2(global_center - half_tile, tile_size)
			field.set_impassable(wall_rect)
