class_name Stage extends Node2D

var data: StageData

@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D
@onready var towers: Node2D = $NavigationRegion2D/Towers

# Lives and gold for the currently loaded stage
var lives: int
var gold: int
var wave: int
var current_wave: WaveData

## TODO: Set from loadout selection scene, probably in GameManager or perhaps a dedicated LoadoutManager
var loadout: Array[TowerData] = [
	Registry.get_tower_data("archer_tower"),
	Registry.get_tower_data("barricade"),
	Registry.get_tower_data("tar_trap"),
	Registry.get_tower_data("tesla_tower")
]

var spawners: Array[Spawner] = []
var wave_is_active: bool = false

const GRID_SIZE = 32

# Tower placement
var _preview_tower: Tower = null
var _preview_pos: Vector2 = Vector2.ZERO ## Used to track placement BEFORE grid snapping, helps the movement feel more natural
var _total_drag_distance_sq: float = 0 ## Tracks how far was travelled between a press and a release. Used to detect tower clicks
var _is_dragging: bool = false
var _last_input_pos: Vector2 = Vector2.ZERO
var _drag_speed_modifier: float = 1.0
const TOWER_TOUCH_DIST_THRESH: float = 96 ## Touch distance from the center of a tower to enter slow drag mode

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
		wave_is_active = true
		current_wave = wave_data
		
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
	
	SignalBus.placement_mode_changed.emit(true)

func exit_placement_mode() -> void:
	if not is_in_placement_mode():
		return
	
	_preview_tower.queue_free()
	_preview_tower = null
	_is_dragging = false
	SignalBus.placement_mode_changed.emit(false)

func is_in_placement_mode() -> bool:
	return _preview_tower != null and is_instance_valid(_preview_tower)

func get_preview_tower_position() -> Vector2:
	if is_in_placement_mode():
		return _preview_tower.global_position
	return Vector2.ZERO

func can_place_preview() -> bool:
	if not _preview_tower or not is_instance_valid(_preview_tower):
		return false

	if _preview_tower.data and _preview_tower.data.cost > gold:
		return false

	var preview_rect: Rect2 = _get_tower_global_rect(_preview_tower)

	# 1. Map boundary check
	var map_rect: Rect2 = get_map_pixel_rect()
	if map_rect.has_area() and not map_rect.encloses(preview_rect):
		return false

	# 2. Tilemap terrain check (every cell covered by preview_rect must be walkable)
	if tiles:
		var min_cell: Vector2i = tiles.local_to_map(tiles.to_local(preview_rect.position + Vector2(1, 1)))
		var max_cell: Vector2i = tiles.local_to_map(tiles.to_local(preview_rect.end - Vector2(1, 1)))

		for x in range(min_cell.x, max_cell.x + 1):
			for y in range(min_cell.y, max_cell.y + 1):
				var cell_pos := Vector2i(x, y)
				var tile_data: TileData = tiles.get_cell_tile_data(cell_pos)
				if not tile_data or tile_data.get_collision_polygons_count(0) > 0:
					return false

	# 3. Check for overlap with already placed towers
	if towers:
		for child in towers.get_children():
			if child is Tower and child != _preview_tower and not child.is_preview:
				var child_rect: Rect2 = _get_tower_global_rect(child)
				if preview_rect.intersects(child_rect):
					return false

	# 4. Check for overlap with active enemies
	var enemy_nodes: Array = []
	if GameManager and GameManager.stage_root and GameManager.stage_root.enemies:
		enemy_nodes = GameManager.stage_root.enemies.get_children()
	else:
		enemy_nodes = get_tree().get_nodes_in_group("enemies")

	for enemy in enemy_nodes:
		if enemy is CharacterBody2D and is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			if preview_rect.grow(16.0).has_point(enemy.global_position):
				return false

	return true

## Converts the current preview_tower into an active tower on the stage and deducts gold
func place_preview() -> void:
	if not _preview_tower:
		return

	if not can_place_preview():
		return

	# All checks passed, place the tower!
	gold -= _preview_tower.data.cost
	SignalBus.gold_changed.emit(gold)
	
	_preview_tower.is_preview = false
	_preview_tower.modulate = Color.WHITE
	
	_generate_navmesh()
	SignalBus.tower_placed.emit()
	
	_preview_tower = null
	_is_dragging = false
	SignalBus.placement_mode_changed.emit(false)

### PRIVATE FUNCTIONS

func _get_tower_local_rect(tower: Tower) -> Rect2:
	if not is_instance_valid(tower):
		return Rect2(-Vector2(16, 16), Vector2(32, 32))

	for child in tower.get_children():
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

	var color_rect = tower.find_child("ColorRect", false, false) as ColorRect
	if color_rect:
		return color_rect.get_rect()

	return Rect2(-Vector2(GRID_SIZE, GRID_SIZE), Vector2(GRID_SIZE * 2, GRID_SIZE * 2))

func _get_tower_global_rect(tower: Tower) -> Rect2:
	var local_rect: Rect2 = _get_tower_local_rect(tower)
	return Rect2(tower.global_position + local_rect.position, local_rect.size)

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
	
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_exit.connect(_on_enemy_exit)
	
	_generate_navmesh()
	
	SignalBus.stage_loaded.emit()

func _process(_delta: float) -> void:
	if _preview_tower and is_instance_valid(_preview_tower):
		var valid: bool = can_place_preview()
		_preview_tower.modulate = Color(0.5, 1.0, 0.5, 0.7) if valid else Color(1.0, 0.4, 0.4, 0.7)


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

func _unhandled_input(event: InputEvent) -> void:
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
	var enemies_remaining: int = 0
	for e in GameManager.stage_root.enemies.get_children():
		if !e.is_queued_for_deletion(): enemies_remaining += 1
	
	if wave_is_active and spawners.all(func(x: Spawner): return !x.is_active()) and enemies_remaining == 0:
		wave_is_active = false
		SignalBus.wave_completed.emit()
		
		gold += current_wave.reward_gold
		SignalBus.gold_changed.emit(gold)
		
		if wave == data.get_waves().size():
			SignalBus.stage_completed.emit()

const AGENT_TIERS: Array[Dictionary] = [
	{"radius": 10, "layer": 1, "ignore_towers": false}, # Small enemies (< 16px, fits in 16x16 gaps)
	{"radius": 16, "layer": 2, "ignore_towers": false}, # Large enemies (>= 16px, requires wider clearance)
	{"radius": 10, "layer": 4, "ignore_towers": true}, # Ghost enemies (ignores towers, respects stage walls)
]

var _tier_regions: Dictionary = {}

func _get_or_create_tier_region(layer: int) -> NavigationRegion2D:
	if _tier_regions.has(layer):
		return _tier_regions[layer]
	
	if navigation_region_2d and (_tier_regions.is_empty() or navigation_region_2d.navigation_layers == layer):
		navigation_region_2d.navigation_layers = layer
		_tier_regions[layer] = navigation_region_2d
		return navigation_region_2d
		
	var new_region = NavigationRegion2D.new()
	new_region.name = "NavRegion_Layer%d" % layer
	new_region.navigation_layers = layer
	add_child(new_region)
	_tier_regions[layer] = new_region
	return new_region

func _generate_navmesh() -> void:
	NavMeshGenerator.generate_navmesh(
		tiles,
		towers,
		navigation_region_2d,
		AGENT_TIERS,
		_get_or_create_tier_region
	)

func _on_enemy_died(enemy: Enemy) -> void:
	gold += enemy.data.gold_reward
	SignalBus.gold_changed.emit(gold)
	_check_wave_completion()

func _on_enemy_exit(enemy: Enemy) -> void:
	lives -= enemy.data.lives_penalty
	SignalBus.lives_changed.emit(lives)
	
	if lives <= 0:
		print("YOU LOSE LOL")

	_check_wave_completion()
