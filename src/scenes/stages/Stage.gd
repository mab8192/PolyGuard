class_name Stage extends Node2D

@export var data: StageData

@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D
@onready var towers: Node2D = $NavigationRegion2D/Towers

# Lives and gold for the currently loaded stage
var lives: int
var gold: int
var wave: int

## TODO: Set from loadout selection scene, probably in GameManager or perhaps a dedicated LoadoutManager
var loadout: Array[TowerData] = [
	Registry.get_tower_data("archer_tower"),
	Registry.get_tower_data("barricade"),
	Registry.get_tower_data("tar_trap")
]

var spawners: Array[Spawner] = []
var wave_active: bool = false
var enemies_alive: int = 0

const GRID_SIZE = 32

# Tower placement
var _preview_tower: Tower = null
var _preview_pos: Vector2 = Vector2.ZERO ## Used to track placement BEFORE grid snapping, helps the movement feel more natural
var _total_drag_distance_sq: float = 0 ## Tracks how far was travelled between a press and a release. Used to detect tower clicks
var _is_dragging: bool = false
var _last_input_pos: Vector2 = Vector2.ZERO
var _drag_speed_modifier: float = 1.0
const TOWER_TOUCH_DIST_THRESH: float = 150  ## Touch distance from the center of a tower to enter slow drag mode

### PUBLIC API

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
	var wave_data: WaveData = data.get_wave(wave)
	if wave_data:
		wave_active = true
		
		for node in get_tree().get_nodes_in_group("spawners"):
			if node is Spawner:
				spawners.append(node)
		
		# Assign spawn groups to spawners in round-robin fashion and run them
		var spawner_count = spawners.size()
		if spawner_count > 0:
			for i in range(wave_data.spawns.size()):
				var spawn_group = wave_data.spawns[i]
				var spawner = spawners[i % spawner_count]
				spawner.run(spawn_group)
		
		wave += 1
		SignalBus.wave_changed.emit(wave)
		SignalBus.wave_started.emit()
	else:
		printerr("No more waves!")

## Creates a new preview_tower out of the given tower data or scene
func enter_placement_mode(tower_input: TowerData) -> void:
	exit_placement_mode()
	
	_is_dragging = false
	_total_drag_distance_sq = 0
	
	# Create the new preview tower
	_preview_tower = tower_input.create()
	if not _preview_tower:
		push_error("Must be a tower scene!")
		return

	# Add it to the scene tree
	towers.add_child(_preview_tower)
	
	# Mark this tower as a preview
	_preview_tower.is_preview = true
	
	# Center on screen in world coordinates (snapped to the placement grid)
	var center_pos = Vector2.ZERO
	if GameManager.camera:
		center_pos = GameManager.camera.global_position
	else:
		center_pos = get_viewport_rect().size / 2.0
	
	var snapped_pos = _snap_to_grid(center_pos)
	_preview_tower.global_position = snapped_pos
	_preview_pos = snapped_pos

func exit_placement_mode() -> void:
	if _preview_tower:
		_preview_tower.queue_free()
		_preview_tower = null
	_is_dragging = false

func can_place_preview() -> bool:
	if _preview_tower.data.cost > gold: return false
	
	# TODO: Check enemies, "walls", previously placed towers, etc.
	
	return true

## Converts the current preview_tower into an active tower on the stage and deducts gold
func place_preview() -> void:
	print("PLACE TOWER")
	if not _preview_tower:
		return

	if not can_place_preview():
		return

	# All checks passed, place the tower!
	gold -= _preview_tower.data.cost
	SignalBus.gold_changed.emit(gold)
	
	_preview_tower.is_preview = false
	
	_generate_navmesh()
	SignalBus.tower_placed.emit()
	
	_preview_tower = null
	exit_placement_mode()

### PRIVATE FUNCTIONS

func _rect_intersects_circle(rect: Rect2, circle_center: Vector2, radius: float) -> bool:
	var closest_point = Vector2(
		clamp(circle_center.x, rect.position.x, rect.end.x),
		clamp(circle_center.y, rect.position.y, rect.end.y)
	)
	var distance_squared = circle_center.distance_squared_to(closest_point)
	return distance_squared < (radius * radius)

func _ready() -> void:
	lives = data.starting_lives
	gold = data.starting_gold
	
	SignalBus.lives_changed.emit(lives)
	SignalBus.gold_changed.emit(gold)
	
	SignalBus.enemy_spawned.connect(_on_enemy_spawned)
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_exit.connect(_on_enemy_exit)
	
	_generate_navmesh()

func _process(_delta: float) -> void:
	pass

func _handle_press(pos: Vector2) -> void:
	_is_dragging = true
	_last_input_pos = pos
	_total_drag_distance_sq = 0
	
	var dist = pos.distance_to(_preview_tower.global_position)
	_drag_speed_modifier = 1.0 if dist < TOWER_TOUCH_DIST_THRESH else 0.5
	
func _handle_release(_pos: Vector2) -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	
	var on_tower = _pos.distance_to(_preview_tower.global_position) < TOWER_TOUCH_DIST_THRESH
	if _total_drag_distance_sq < 100 and on_tower and can_place_preview():
		place_preview()
	
func _handle_drag(delta: Vector2) -> void:
	if not _is_dragging: return
	
	delta *= _drag_speed_modifier
	
	_preview_pos += delta
	_total_drag_distance_sq += delta.length_squared()
	
	_preview_tower.global_position = _snap_to_grid(_preview_pos)

func _input(event: InputEvent) -> void:
	if _preview_tower == null:
		return

	var pos = get_global_mouse_position()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_handle_press(pos)
			get_viewport().set_input_as_handled()
		else:
			if _is_dragging:
				_handle_release(pos)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if _is_dragging:
			_handle_drag(pos - _last_input_pos)
			_last_input_pos = pos
			get_viewport().set_input_as_handled()

func _snap_to_grid(glob_pos: Vector2) -> Vector2:
	return glob_pos.snapped(Vector2(GRID_SIZE, GRID_SIZE))

func _check_wave_completion() -> void:
	if wave_active and spawners.all(func(x: Spawner): return !x.is_active()) and enemies_alive == 0:
		print("WAVE COMPLETE")
		wave_active = false
		SignalBus.wave_completed.emit()
		
		if wave == data.get_waves().size():
			print("STAGE COMPLETE")

@export var agent_radius: float = GRID_SIZE / 2

func _generate_navmesh() -> void:
	var nav_poly: NavigationPolygon = NavigationPolygon.new()
	var tile_size: Vector2 = Vector2(tiles.tile_set.tile_size) * tiles.scale
	
	# We subdivide the grid to have accurate radius carving.
	var sub_step: float = GRID_SIZE / 2.0
	var sub_size: Vector2 = Vector2(sub_step, sub_step)
	var sub_half: Vector2 = sub_size / 2.0

	var subs_per_tile_x: int = round(tile_size.x / sub_step)
	var subs_per_tile_y: int = round(tile_size.y / sub_step)

	# 1. Collect all obstacle AABBs (Walls + Towers) in NavigationRegion2D local space
	var obstacle_rects: Array[Rect2] = []

	# A. Wall tile AABBs
	for cell_pos in tiles.get_used_cells():
		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
			var region_center: Vector2 = navigation_region_2d.to_local(global_center)
			var rect: Rect2 = Rect2(region_center - (tile_size / 2.0), tile_size)
			obstacle_rects.append(rect)

	# B. Placed Tower AABBs
	for tower in towers.get_children():
		if tower is Tower and not tower.is_preview:
			var region_pos: Vector2 = navigation_region_2d.to_local(tower.global_position)
			
			var found_shape = false
			# Find the physical collision shape to get the precise footprint
			for child in tower.get_children():
				if child is CollisionShape2D and child.shape is RectangleShape2D:
					var shape_size = child.shape.size
					var local_offset = child.position
					var rect = Rect2(region_pos + local_offset - (shape_size / 2.0), shape_size)
					obstacle_rects.append(rect)
					found_shape = true
					break
			
			if not found_shape:
				var tower_size: Vector2 = Vector2(64, 64)
				var rect: Rect2 = Rect2(region_pos - (tower_size / 2.0), tower_size)
				obstacle_rects.append(rect)

	# 2. Build grid of safe sub-quads and share vertices
	var vertex_map: Dictionary = {}
	var all_vertices: PackedVector2Array = []
	
	var get_vertex_idx = func(pos: Vector2) -> int:
		var key = Vector2(round(pos.x), round(pos.y))
		if vertex_map.has(key):
			return vertex_map[key]
		var idx = all_vertices.size()
		all_vertices.append(pos)
		vertex_map[key] = idx
		return idx

	for cell_pos in tiles.get_used_cells():
		var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			continue

		var global_center: Vector2 = tiles.to_global(tiles.map_to_local(cell_pos))
		var region_center: Vector2 = navigation_region_2d.to_local(global_center)
		var tile_top_left: Vector2 = region_center - (tile_size / 2.0)

		for sub_x in range(subs_per_tile_x):
			for sub_y in range(subs_per_tile_y):
				var sub_center: Vector2 = tile_top_left + Vector2(
					sub_x * sub_step + sub_half.x,
					sub_y * sub_step + sub_half.y
				)
				var sub_rect: Rect2 = Rect2(sub_center - sub_half, sub_size)

				# Check distance to all obstacles
				var is_safe: bool = true
				for obs_rect in obstacle_rects:
					var dx = maxf(0.0, maxf(sub_rect.position.x - obs_rect.end.x, obs_rect.position.x - sub_rect.end.x))
					var dy = maxf(0.0, maxf(sub_rect.position.y - obs_rect.end.y, obs_rect.position.y - sub_rect.end.y))
					var dist = sqrt(dx * dx + dy * dy)
					
					if dist < agent_radius - 0.1:
						is_safe = false
						break

				if is_safe:
					var top_left: Vector2 = sub_center + Vector2(-sub_half.x, -sub_half.y)
					var top_right: Vector2 = sub_center + Vector2(sub_half.x, -sub_half.y)
					var bottom_right: Vector2 = sub_center + Vector2(sub_half.x, sub_half.y)
					var bottom_left: Vector2 = sub_center + Vector2(-sub_half.x, sub_half.y)

					var i1 = get_vertex_idx.call(top_left)
					var i2 = get_vertex_idx.call(top_right)
					var i3 = get_vertex_idx.call(bottom_right)
					var i4 = get_vertex_idx.call(bottom_left)

					nav_poly.add_polygon(PackedInt32Array([i1, i2, i3, i4]))

	nav_poly.vertices = all_vertices
	navigation_region_2d.navigation_polygon = nav_poly

### SIGNAL HANDLERS

func _on_enemy_spawned(_enemy: Enemy) -> void:
	enemies_alive += 1

func _on_enemy_died(enemy: Enemy) -> void:
	enemies_alive -= 1
	gold += enemy.gold_reward
	_check_wave_completion()

func _on_enemy_exit(enemy: Enemy) -> void:
	lives -= enemy.lives_penalty
	enemies_alive -= 1
	SignalBus.lives_changed.emit(lives)
	
	if lives <= 0:
		print("YOU LOSE LOL")

	_check_wave_completion()
