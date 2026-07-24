class_name Stage extends Node2D

@export var data: StageData
@export var spawners: Array[Spawner]

@onready var tiles: TileMapLayer = $NavigationRegion2D/Tiles

# Lives and gold for the currently loaded stage
var lives: int
var gold: int
var wave: int

var wave_active: bool = false
var enemies_alive: int = 0

# Debug
@onready var color_rect: ColorRect = $ColorRect

func get_map_pixel_rect() -> Rect2:
	var used_rect: Rect2i = tiles.get_used_rect()
	var tile_size: Vector2i = tiles.tile_set.tile_size
	
	var world_pos = Vector2(used_rect.position * tile_size)
	var world_size = Vector2(used_rect.size * tile_size)
	
	return Rect2(world_pos, world_size)

func start_next_wave() -> void:
	var wave_data: WaveData = data.get_wave(wave)
	if wave_data:
		wave_active = true
		# TODO: Assign spawn groups to spawners and then call run()
		spawners[0].run(wave_data.spawns[0])
		wave += 1
		SignalBus.wave_changed.emit(wave)
		SignalBus.wave_started.emit()
	else:
		printerr("No more waves!")

func _ready() -> void:
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
