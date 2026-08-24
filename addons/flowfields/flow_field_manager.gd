extends Node

## ============================================================================
## FlowFieldManager
## ----------------------------------------------------------------------------
## Autoload singleton that owns named FlowField instances so multiple systems
## (spawners, agents, debug tools) can create, retrieve, and bake shared fields.
## ============================================================================

signal flow_fields_updated()

var fields: Dictionary = {} # String id -> FlowField

var astar_grid: AStarGrid2D = null
var grid_origin: Vector2 = Vector2.ZERO
var grid_cell_size: float = 16.0
var grid_width: int = 0
var grid_height: int = 0


func setup_astar(p_width: int, p_height: int, p_cell_size: float, p_origin: Vector2) -> void:
	grid_width = p_width
	grid_height = p_height
	grid_cell_size = p_cell_size
	grid_origin = p_origin
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, p_width, p_height)
	astar_grid.cell_size = Vector2(p_cell_size, p_cell_size)
	astar_grid.offset = p_origin + Vector2(p_cell_size * 0.5, p_cell_size * 0.5)
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar_grid.update()


func reset_astar() -> void:
	if astar_grid:
		astar_grid.fill_solid_region(Rect2i(0, 0, grid_width, grid_height), false)
		astar_grid.fill_weight_scale_region(Rect2i(0, 0, grid_width, grid_height), 1.0)


func set_astar_rect_solid(rect: Rect2, solid: bool) -> void:
	if not astar_grid:
		return
	var min_x: int = clampi(int(floor((rect.position.x - grid_origin.x) / grid_cell_size)), 0, grid_width - 1)
	var max_x: int = clampi(int(ceil((rect.end.x - grid_origin.x) / grid_cell_size)), 0, grid_width)
	var min_y: int = clampi(int(floor((rect.position.y - grid_origin.y) / grid_cell_size)), 0, grid_height - 1)
	var max_y: int = clampi(int(ceil((rect.end.y - grid_origin.y) / grid_cell_size)), 0, grid_height)
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var cell := Vector2i(x, y)
			if astar_grid.is_in_bounds(cell.x, cell.y):
				astar_grid.set_point_solid(cell, solid)


func set_astar_rect_weight(rect: Rect2, weight: float) -> void:
	if not astar_grid:
		return
	var min_x: int = clampi(int(floor((rect.position.x - grid_origin.x) / grid_cell_size)), 0, grid_width - 1)
	var max_x: int = clampi(int(ceil((rect.end.x - grid_origin.x) / grid_cell_size)), 0, grid_width)
	var min_y: int = clampi(int(floor((rect.position.y - grid_origin.y) / grid_cell_size)), 0, grid_height - 1)
	var max_y: int = clampi(int(ceil((rect.end.y - grid_origin.y) / grid_cell_size)), 0, grid_height)
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var cell := Vector2i(x, y)
			if astar_grid.is_in_bounds(cell.x, cell.y):
				astar_grid.set_point_weight_scale(cell, weight)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = (world_pos - grid_origin) / grid_cell_size
	return Vector2i(int(floor(local.x)), int(floor(local.y)))


func grid_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * grid_cell_size + grid_cell_size * 0.5, cell.y * grid_cell_size + grid_cell_size * 0.5)


func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	if not astar_grid:
		return PackedVector2Array()
	var start_cell: Vector2i = world_to_grid(from_world)
	var end_cell: Vector2i = world_to_grid(to_world)
	
	if not astar_grid.is_in_bounds(start_cell.x, start_cell.y) or not astar_grid.is_in_bounds(end_cell.x, end_cell.y):
		return PackedVector2Array()
	
	if astar_grid.is_point_solid(start_cell):
		start_cell = _find_nearest_walkable_astar_cell(start_cell)
		if start_cell == Vector2i(-1, -1):
			return PackedVector2Array()

	if astar_grid.is_point_solid(end_cell):
		end_cell = _find_nearest_walkable_astar_cell(end_cell)
		if end_cell == Vector2i(-1, -1):
			return PackedVector2Array()

	var path: PackedVector2Array = astar_grid.get_point_path(start_cell, end_cell)
	if path.size() > 0:
		path.append(to_world)
	return path


func _find_nearest_walkable_astar_cell(center: Vector2i) -> Vector2i:
	if not astar_grid:
		return Vector2i(-1, -1)
	if astar_grid.is_in_bounds(center.x, center.y) and not astar_grid.is_point_solid(center):
		return center
	for r in range(1, 4):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) == r or abs(dy) == r:
					var neighbor := center + Vector2i(dx, dy)
					if astar_grid.is_in_bounds(neighbor.x, neighbor.y) and not astar_grid.is_point_solid(neighbor):
						return neighbor
	return Vector2i(-1, -1)


func create_field(id: String, p_width: int, p_height: int, p_cell_size: float,
		p_origin: Vector2 = Vector2.ZERO) -> FlowField:
	var field: FlowField = FlowField.new()
	if field.has_method("init_grid"):
		field.init_grid(p_width, p_height, int(p_cell_size), p_origin)
	fields[id] = field
	return field


func register_field(id: String, field: FlowField) -> void:
	fields[id] = field


func get_field(id: String) -> FlowField:
	if fields.has(id):
		return fields[id] as FlowField
	return null


func has_field(id: String) -> bool:
	return fields.has(id)


func remove_field(id: String) -> void:
	fields.erase(id)


func clear() -> void:
	fields.clear()


func bake_field(id: String) -> void:
	var field: FlowField = get_field(id)
	if field == null:
		push_warning("FlowFieldManager: no field registered with id '%s'" % id)
		return
	field.rebuild()


func bake_all() -> void:
	for id: String in fields:
		bake_field(id)


func notify_fields_updated() -> void:
	flow_fields_updated.emit()
	SignalBus.flow_fields_updated.emit()
