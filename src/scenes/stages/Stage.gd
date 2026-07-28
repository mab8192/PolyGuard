class_name Stage extends Node2D

@export var data: StageData
@export var spawners: Array[Spawner]

@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D
@onready var towers: Node2D = $NavigationRegion2D/Towers

# Lives and gold for the currently loaded stage
var lives: int
var gold: int
var wave: int

var wave_active: bool = false
var enemies_alive: int = 0

const GRID_SIZE = 64

# Tower placement
var preview_tower: Tower = null

# Debug
var debug_drawer: Node2D

func get_map_pixel_rect() -> Rect2:
	var used_rect: Rect2i = tiles.get_used_rect()
	var tile_size: Vector2i = tiles.tile_set.tile_size
	
	var world_pos = Vector2(used_rect.position * tile_size)
	var world_size = Vector2(used_rect.size * tile_size) * tiles.scale
	
	return Rect2(world_pos, world_size)

func start_next_wave() -> void:
	var wave_data: WaveData = data.get_wave(wave)
	if wave_data:
		wave_active = true
		
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

func enter_placement_mode(tower_scene: PackedScene) -> void:
	cancel_placement_mode()
	
	preview_tower = tower_scene.instantiate() as Tower
	if preview_tower:
		preview_tower.is_preview = true
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = (mouse_pos / GRID_SIZE).floor() * GRID_SIZE
		preview_tower.global_position = snapped_pos
		towers.add_child(preview_tower)

func cancel_placement_mode() -> void:
	if preview_tower:
		preview_tower.queue_free()
		preview_tower = null

func _input(event: InputEvent) -> void:
	if preview_tower == null:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_tower()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_placement_mode()
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			cancel_placement_mode()

func is_valid_placement(grid_pos: Vector2, size: Vector2i) -> bool:
	var new_rect = Rect2(grid_pos, Vector2(size) * GRID_SIZE)
	
	for x in range(size.x):
		for y in range(size.y):
			var cell_pos = grid_pos + Vector2(x, y) * GRID_SIZE
			
			# 1. Check for walls (tiles with physics colliders)
			var local_pos = tiles.to_local(cell_pos)
			var map_pos = tiles.local_to_map(local_pos)
			var tile_data = tiles.get_cell_tile_data(map_pos)
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				return false

			# 2. Check for previously placed towers
			for tower in towers.get_children():
				if tower == preview_tower:
					continue
				if tower is Tower:
					var t_rect = Rect2(tower.global_position, Vector2(tower.size) * GRID_SIZE)
					if new_rect.intersects(t_rect):
						return false

			# 3. Check for enemies
			var cell_rect = Rect2(cell_pos, Vector2(GRID_SIZE, GRID_SIZE))
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy is Node2D:
					var enemy_pos = enemy.global_position
					var radius = 8.0
					var collision_shape = enemy.get_node_or_null("CollisionShape2D")
					if collision_shape and collision_shape.shape is CircleShape2D:
						radius = collision_shape.shape.radius
					
					if _rect_intersects_circle(cell_rect, enemy_pos, radius):
						return false

	return true

func _rect_intersects_circle(rect: Rect2, circle_center: Vector2, radius: float) -> bool:
	var closest_point = Vector2(
		clamp(circle_center.x, rect.position.x, rect.end.x),
		clamp(circle_center.y, rect.position.y, rect.end.y)
	)
	var distance_squared = circle_center.distance_squared_to(closest_point)
	return distance_squared < (radius * radius)

func place_tower() -> void:
	if not preview_tower:
		return
		
	var grid_pos = preview_tower.global_position
	var size = preview_tower.size
	
	if not is_valid_placement(grid_pos, size):
		return
		
	if preview_tower.cost > gold:
		return
		
	# All checks passed, place the tower!
	gold -= preview_tower.cost
	SignalBus.gold_changed.emit(gold)
	
	preview_tower.is_preview = false
	preview_tower = null
	
	navigation_region_2d.bake_navigation_polygon(true)
	SignalBus.tower_placed.emit()

func _process(_delta: float) -> void:
	if preview_tower:
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = (mouse_pos / GRID_SIZE).floor() * GRID_SIZE
		preview_tower.global_position = snapped_pos
		
	if debug_drawer:
		debug_drawer.queue_redraw()

func _on_debug_draw() -> void:
	if not preview_tower:
		return
		
	var grid_pos = preview_tower.global_position
	var local_pos = debug_drawer.to_local(grid_pos)
	
	var is_valid = is_valid_placement(grid_pos, preview_tower.size)
	var fill_color = Color(0.2, 0.7, 1.0, 0.4) if is_valid else Color(1.0, 0.2, 0.2, 0.4)
	var border_color = Color(0.2, 0.7, 1.0, 0.9) if is_valid else Color(1.0, 0.2, 0.2, 0.9)
	
	# Draw a debug rectangle at the snapped position matching tower size
	var rect_size = Vector2(preview_tower.size) * GRID_SIZE
	var rect = Rect2(local_pos, rect_size)
	debug_drawer.draw_rect(rect, fill_color, true)
	debug_drawer.draw_rect(rect, border_color, false, 2.0)


func _ready() -> void:
	# Set up debug drawer to draw on top of everything
	debug_drawer = Node2D.new()
	debug_drawer.z_index = 100
	debug_drawer.draw.connect(_on_debug_draw)
	add_child(debug_drawer)

	if not data:
		push_error("Need to provide data for stage")
		return
	
	# Set starting values
	lives = data.starting_lives
	gold = data.starting_gold
	wave = 0
	SignalBus.gold_changed.emit(gold)
	SignalBus.lives_changed.emit(lives)

	# Hook up our signals
	SignalBus.enemy_exit.connect(_on_enemy_exit)
	SignalBus.enemy_spawned.connect(_on_enemy_spawned)
	SignalBus.enemy_died.connect(_on_enemy_died)

	# Connect spawner finished signals
	for spawner in spawners:
		spawner.finished.connect(_check_wave_completion)

	# DEBUG
	# Immediately start wave 1
	start_next_wave()
	
func _on_enemy_spawned(_enemy: Enemy) -> void:
	enemies_alive += 1

func _on_enemy_died(_enemy: Enemy) -> void:
	enemies_alive -= 1
	_check_wave_completion()

func _on_enemy_exit(enemy: Enemy) -> void:
	lives -= enemy.lives_penalty
	SignalBus.lives_changed.emit(lives)

	if lives <= 0:
		print("YOU LOSE LOL")

	_check_wave_completion()

func _check_wave_completion() -> void:
	if wave_active and spawners.all(func (x: Spawner): return !x.is_active()) and enemies_alive == 0:
		print("WAVE COMPLETE")
		wave_active = false
		SignalBus.wave_completed.emit()
		
		if wave == data.get_waves().size():
			print("STAGE COMPLETE")
