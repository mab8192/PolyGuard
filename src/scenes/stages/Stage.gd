class_name Stage extends Node2D

var data: StageData

@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D
@onready var towers: Node2D = $NavigationRegion2D/Towers

var wave_manager: WaveManager
var placement_manager: TowerPlacementManager
var effect_manager: EffectManager

# Stage economy and life tracking state
var lives: int
var gold: int
var score: int = 0

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
		gold = data.starting_gold
	
	SignalBus.lives_changed.emit(lives)
	SignalBus.gold_changed.emit(gold)
	SignalBus.score_changed.emit(score)
	
	wave_manager = WaveManager.new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)
	
	placement_manager = TowerPlacementManager.new()
	placement_manager.name = "TowerPlacementManager"
	add_child(placement_manager)
	
	effect_manager = EffectManager.new()
	
	effect_manager.setup()
	wave_manager.setup(self)
	placement_manager.setup(self, wave_manager)
	
	SignalBus.tower_placed.connect(generate_navmesh)
	SignalBus.tower_destroyed.connect(generate_navmesh)
	generate_navmesh()

func _unhandled_input(event: InputEvent) -> void:
	if placement_manager and placement_manager.handle_unhandled_input(event):
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("ui_cancel"):
		var hud = get_tree().current_scene.find_child("HUD", true, false)
		if hud and hud.has_method("open_pause_menu"):
			hud.open_pause_menu()
			get_viewport().set_input_as_handled()

### PUBLIC API & ECONOMY HELPERS

func deduct_gold(amount: int) -> void:
	gold -= amount
	SignalBus.gold_changed.emit(gold)

func add_gold(amount: int) -> void:
	gold += amount
	SignalBus.gold_changed.emit(gold)

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

func place_preview() -> void:
	if placement_manager:
		placement_manager.place_preview()

func generate_navmesh() -> void:
	NavMeshGenerator.generate_navmesh(self)
