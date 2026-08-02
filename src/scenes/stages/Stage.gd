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

const GRID_SIZE = 32

# Tower placement
var _preview_tower: Tower = null
var _preview_pos: Vector2 = Vector2.ZERO ## Used to track placement BEFORE grid snapping, helps the movement feel more natural
var _total_drag_distance_sq: float = 0 ## Tracks how far was travelled between a press and a release. Used to detect tower clicks
var _is_dragging: bool = false
var _last_input_pos: Vector2 = Vector2.ZERO
var _drag_speed_modifier: float = 1.0

### PUBLIC API

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

## Creates a new preview_tower out of the given tower scene
func enter_placement_mode(tower_scene: PackedScene) -> void:
	exit_placement_mode()
	
	_is_dragging = false
	_total_drag_distance_sq = 0
	
	# Create the new preview tower
	_preview_tower = tower_scene.instantiate() as Tower
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
	if _preview_tower.cost > gold: return false
	
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
	gold -= _preview_tower.cost
	SignalBus.gold_changed.emit(gold)
	
	_preview_tower.is_preview = false
	_preview_tower = null
	
	navigation_region_2d.bake_navigation_polygon(true)
	SignalBus.tower_placed.emit()

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

func _process(_delta: float) -> void:
	pass

func _handle_press(pos: Vector2) -> void:
	_is_dragging = true
	_last_input_pos = pos
	_total_drag_distance_sq = 0
	
	var dist = pos.distance_to(_preview_tower.global_position)
	_drag_speed_modifier = 1.0 if dist < 100 else 0.5
	
func _handle_release(_pos: Vector2) -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	
	var on_tower = true # TODO
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
