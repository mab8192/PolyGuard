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

const ARCHER_TOWER = preload("uid://dg12a81rft006")
const GRID_SIZE = 64

# Debug
var debug_drawer: Node2D

func get_map_pixel_rect() -> Rect2:
	var used_rect: Rect2i = tiles.get_used_rect()
	var tile_size: Vector2i = tiles.tile_set.tile_size
	
	var world_pos = Vector2(used_rect.position * tile_size)
	var world_size = Vector2(used_rect.size * tile_size) * tiles.scale
	
	print(world_size)
	
	return Rect2(world_pos, world_size)

func start_next_wave() -> void:
	var wave_data: WaveData = data.get_wave(wave)
	if wave_data:
		wave_active = true
		# TODO: Assign spawn groups to spawners and then call run()
		for spawn_group in wave_data.spawns:
			spawners[0].run(spawn_group)
		wave += 1
		SignalBus.wave_changed.emit(wave)
		SignalBus.wave_started.emit()
	else:
		printerr("No more waves!")

func enter_placement_mode(tower: TowerData) -> void:
	pass
	# TODO: Show preview, do other things

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_tower(null, Vector2i.ZERO)

func is_valid_placement(grid_pos: Vector2) -> bool:
	# 1. Check for walls (tiles with physics colliders)
	var local_pos = tiles.to_local(grid_pos)
	var map_pos = tiles.local_to_map(local_pos)
	var tile_data = tiles.get_cell_tile_data(map_pos)
	if tile_data and tile_data.get_collision_polygons_count(0) > 0:
		return false

	# 2. Check for previously placed towers
	for tower in towers.get_children():
		if tower is Tower and tower.global_position.distance_to(grid_pos) < 1.0:
			return false

	# 3. Check for enemies
	var cell_rect = Rect2(grid_pos, Vector2(GRID_SIZE, GRID_SIZE))
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

func place_tower(data: TowerData, pos: Vector2i) -> void:
	var mouse_pos = get_global_mouse_position()
	var grid_pos = (mouse_pos / GRID_SIZE).floor() * GRID_SIZE
	
	if not is_valid_placement(grid_pos):
		return
		
	var tower = ARCHER_TOWER.instantiate() as Tower
	tower.global_position = grid_pos
	
	towers.add_child(tower)
	
	navigation_region_2d.bake_navigation_polygon(true)

func _process(_delta: float) -> void:
	if debug_drawer:
		debug_drawer.queue_redraw()

func _on_debug_draw() -> void:
	var mouse_pos = debug_drawer.get_global_mouse_position()
	var snapped_pos = (mouse_pos / GRID_SIZE).floor() * GRID_SIZE
	var local_pos = debug_drawer.to_local(snapped_pos)
	
	var is_valid = is_valid_placement(snapped_pos)
	var fill_color = Color(0.2, 0.7, 1.0, 0.4) if is_valid else Color(1.0, 0.2, 0.2, 0.4)
	var border_color = Color(0.2, 0.7, 1.0, 0.9) if is_valid else Color(1.0, 0.2, 0.2, 0.9)
	
	# Draw a 16x16 debug rectangle at the snapped position
	var rect = Rect2(local_pos, Vector2(GRID_SIZE, GRID_SIZE))
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
	SignalBus.enemy_spawned.connect(func (_enemy: Enemy): enemies_alive += 1)
	SignalBus.enemy_died.connect(func (_enemy: Enemy): enemies_alive -= 1)

	# DEBUG
	# Immediately start wave 1
	start_next_wave()
	
func _on_enemy_exit(enemy: Enemy) -> void:
	lives -= enemy.lives_penalty
	SignalBus.lives_changed.emit(lives)

	if (lives <= 0):
		print("YOU LOSE LOL")

	if wave_active and spawners.all(func (x: Spawner): return !x.is_active()) and enemies_alive == 0:
		print("WAVE COMPLETE")
		wave_active = false
		SignalBus.wave_completed.emit()
		
		if wave == data.get_waves().size():
			print("STAGE COMPLETE")
