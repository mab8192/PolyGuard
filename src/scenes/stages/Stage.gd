class_name Stage extends Node2D

var data: StageData

@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D
@onready var towers: Node2D = $NavigationRegion2D/Towers

var wave_manager: WaveManager
var placement_manager: TowerPlacementManager
var effect_manager: EffectManager
var flow_field_manager: FlowFieldManager

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
	
	flow_field_manager = FlowFieldManager.new()
	flow_field_manager.name = "FlowFieldManager"
	add_child(flow_field_manager)

	effect_manager = EffectManager.new()
	
	effect_manager.setup()
	wave_manager.setup(self)
	placement_manager.setup(self, wave_manager)
	flow_field_manager.setup(self)

func _unhandled_input(event: InputEvent) -> void:
	if placement_manager and placement_manager.handle_unhandled_input(event):
		get_viewport().set_input_as_handled()
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		var click_pos = get_global_mouse_position()
		var clicked_tower = _find_tower_at(click_pos)
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
		var hud = get_tree().current_scene.find_child("HUD", true, false)
		if hud and hud.has_method("open_pause_menu"):
			hud.open_pause_menu()
			get_viewport().set_input_as_handled()

func _find_tower_at(pos: Vector2) -> Tower:
	if not towers:
		return null
	
	var candidates: Array[Tower] = []
	for child in towers.get_children():
		if child is Tower and is_instance_valid(child) and not child.is_preview and not child.is_queued_for_deletion():
			var rect = _get_tower_global_rect(child).grow(8.0)
			if rect.has_point(pos):
				candidates.append(child)
	
	if candidates.is_empty():
		return null
	
	candidates.sort_custom(func(a: Tower, b: Tower) -> bool:
		return a.global_position.distance_squared_to(pos) < b.global_position.distance_squared_to(pos)
	)
	return candidates[0]

func _get_tower_global_rect(node: Node2D) -> Rect2:
	if placement_manager:
		return placement_manager._get_tower_global_rect(node)
	return Rect2(node.global_position - Vector2(32, 32), Vector2(64, 64))

### PUBLIC API & ECONOMY HELPERS

func select_tower(tower: Tower) -> void:
	if selected_tower == tower:
		return
	
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.is_selected = false
	
	selected_tower = tower
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.is_selected = true
		SignalBus.tower_selected.emit(selected_tower)
	else:
		SignalBus.tower_deselected.emit()

func deselect_tower() -> void:
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.is_selected = false
	selected_tower = null
	SignalBus.tower_deselected.emit()

func get_selected_tower() -> Tower:
	if selected_tower and is_instance_valid(selected_tower):
		return selected_tower
	return null

func sell_selected_tower() -> void:
	if not selected_tower or not is_instance_valid(selected_tower):
		return
	
	var tower_to_sell = selected_tower
	var sell_value = tower_to_sell.get_sell_value()
	
	deselect_tower()
	add_energy(sell_value)
	SignalBus.tower_sold.emit(tower_to_sell, sell_value)
	tower_to_sell._on_died()

func repair_selected_tower() -> bool:
	if not selected_tower or not is_instance_valid(selected_tower):
		return false
	var cost = selected_tower.get_repair_cost()
	if cost <= 0 or energy < cost:
		return false
	deduct_energy(cost)
	var success = selected_tower.repair()
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

func generate_navmesh() -> void:
	NavMeshGenerator.generate_navmesh(self)
